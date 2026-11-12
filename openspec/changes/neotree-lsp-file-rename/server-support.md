# File-rename LSP support

Checked on 2026-11-12 against the language servers in README's `MasonInstall`
command. Debug adapters, formatters, and import tools are excluded.

`workspace/willRenameFiles` is a request returning a possible `WorkspaceEdit`
before a rename. `workspace/didRenameFiles` is a notification after success;
it has no response containing edits. `textDocument/rename` and `renameProvider`
describe symbol rename and do not prove either file-rename method is supported.

## Supporting servers

| Mason package | Neovim client | willRenameFiles | didRenameFiles | Evidence and limits |
| --- | --- | --- | --- | --- |
| `typescript-language-server` 6.0.1 | `ts_ls` | Yes | Not advertised | Local initialize result matches [server capability and handler source](https://github.com/typescript-language-server/typescript-language-server/blob/master/src/lsp-server.ts). Filters cover JS/TS files and folders. It asks tsserver for file-rename edits; project analysis determines which references change. |
| `basedpyright` 1.40.1 | `basedpyright` | Yes | Not advertised | Local initialize result and [server source](https://github.com/DetachHead/basedpyright/blob/main/packages/pyright-internal/src/languageServerBase.ts). Advertises a broad `**/*` filter; edit coverage depends on its Python project/import analysis. |
| `rust-analyzer` 2026-09-28 (`0.3.3065-standalone`) | rustaceanvim-managed `rust-analyzer` | Yes | Not advertised | Local initialize result and [capabilities source](https://github.com/rust-lang/rust-analyzer/blob/master/crates/rust-analyzer/src/lsp/capabilities.rs). Filters cover `.rs` files and folders. Test module references in an initialized Cargo project. |
| `jdtls` 1.61.0 installed | `jdtls` | Yes, source-confirmed | Not advertised in cited initialization source | [Initialization source](https://github.com/eclipse-jdtls/eclipse.jdt.ls/blob/main/org.eclipse.jdt.ls.core/src/org/eclipse/jdt/ls/core/internal/handlers/InitHandler.java) sets willRename filters for Java files and folders when the client advertises `workspace.fileOperations.willRename`. [Changelog](https://github.com/eclipse-jdtls/eclipse.jdt.ls/blob/main/CHANGELOG.md) records support fixes in 1.35 and folder filters in 1.37. Java was not launched in the local probe; confirm the active client's capabilities during apply. |
| `lua-language-server` 3.19.1 | `lua_ls` | Not advertised | Yes | Local initialize result and [provider source](https://github.com/LuaLS/lua-language-server/blob/master/script/provider/provider.lua). Uses workspace-path filters and handles file/directory URI changes. Notification support alone is not a guarantee that `require` strings will be rewritten. |

## Remaining README language servers

“Not advertised” means no rename file-operation capability was returned by the
installed binary in this probe; it is not a claim that a future release can
never support the method.

| Mason package | Neovim client | willRenameFiles | didRenameFiles | Evidence and distinction |
| --- | --- | --- | --- | --- |
| `gopls` 0.23.0 | `gopls` | Not advertised | Not advertised | Local initialize returns only `workspace.fileOperations.didCreate`. [Initialization source](https://github.com/golang/tools/blob/master/gopls/internal/server/general.go) agrees. Go package/symbol rename is a different path. |
| `clangd` 23.1.0 | `clangd` | Not advertised | Not advertised | Local initialize has no fileOperations. [LSP server source](https://github.com/llvm/llvm-project/blob/main/clang-tools-extra/clangd/ClangdLSPServer.cpp) exposes symbol rename; do not infer header-file refactoring support. |
| `bash-language-server` 5.8.1 | `bashls` | Not advertised | Not advertised | Local initialize has no fileOperations; [server source](https://github.com/bash-lsp/bash-language-server/blob/main/server/src/server.ts). |
| `html-lsp` (`vscode-langservers-extracted` 4.10.0) | `html` | Not advertised | Not advertised | Local initialize has no fileOperations; [HTML server source](https://github.com/microsoft/vscode/blob/main/extensions/html-language-features/server/src/htmlServer.ts). |
| `css-lsp` (`vscode-langservers-extracted` 4.10.0) | `cssls` | Not advertised | Not advertised | Local initialize has no fileOperations; [CSS server source](https://github.com/microsoft/vscode/blob/main/extensions/css-language-features/server/src/cssServer.ts). |
| `json-lsp` (`vscode-langservers-extracted` 4.10.0) | `jsonls` | Not advertised | Not advertised | Local initialize has no fileOperations; [JSON server source](https://github.com/microsoft/vscode/blob/main/extensions/json-language-features/server/src/jsonServer.ts). |
| `sqls` 0.2.48 | `sqls` | Not advertised | Not advertised | Local initialize has no fileOperations; [initialization handler](https://github.com/sqls-server/sqls/blob/master/internal/handler/handler.go). |
| `texlab` 5.26.0 | `texlab` | Not advertised | Not advertised | Local initialize has no fileOperations; [capability source](https://github.com/latex-lsp/texlab/blob/master/crates/texlab/src/server.rs). Symbol/path rename features alone do not establish these workspace methods. |
| `vscode-solidity-server` 0.0.187 | historical `solidity_ls` | Not advertised | Not advertised | Local initialize has no fileOperations; this is [Juan Blanco's server](https://github.com/juanfranblanco/vscode-solidity/blob/master/src/server.ts). Current config actually enables `forge` for Solidity, so installing this Mason package does not mean it runs. `forge` is outside the README package inventory and is not evaluated here. |

## Local evidence and runtime check

The local probe started each of the 13 non-Java installed Mason language-server
binaries in a disposable empty `/tmp` workspace. It sent `initialize` with
`workspace.fileOperations = { dynamicRegistration = true, willRename = true,
didRename = true }`, then `initialized`, handled configuration/registration
requests, and observed registrations for one second. None registered an
additional rename method in that interval. Versions above come from Mason
receipts and serverInfo where supplied. No rename request or project-file
mutation was performed. This checks protocol advertisement, not actual import
refactoring, and is not an exhaustive dynamic-registration test in real projects.

After opening a real project, inspect the running clients from Neovim:

```lua
for _, client in ipairs(vim.lsp.get_clients()) do
  local workspace = client.server_capabilities.workspace or {}
  vim.print(client.name, workspace.fileOperations)
end
```

The fork's native `filesystem/lib/lsp_rename.lua` uses this server-capability table
and its filters, including URI scheme, file/folder type, glob and case options.
Methods advertised only through dynamic registrations remain unsupported by the
integration. Do not force methods merely because a server appears in this inventory.

Metals is mentioned as supported in the plugin README and has a plugin spec here,
but it is absent from the README Mason command. `move_analyzer` is also absent
from that command. Neither is silently added to the requested support list.

## Integration API evidence

The following plugin sources informed the initial implementation and subsequent
replacement. The current implementation has no `nvim-lsp-file-operations`
dependency: the Neo-tree fork owns `methods(client, path)` and `hooks(clients)`;
the config retains project discovery, the picker, and confirmation policy.

- [Direct callbacks and rename implementation](https://github.com/antosha417/nvim-lsp-file-operations/blob/master/lua/lsp-file-operations/init.lua): `will_rename` and `did_rename` accept old/new names; `rename()` additionally owns disk and buffer changes.
- [Configuration and automatic subscriptions](https://github.com/antosha417/nvim-lsp-file-operations/blob/master/lua/lsp-file-operations/config.lua): `setup()` installs tree integrations; `config.set()` configures the library without that step.
- [Runtime command guard](https://github.com/antosha417/nvim-lsp-file-operations/blob/master/plugin/lsp-file-operations.lua): runtime sourcing creates `:LFO` unless its loaded flag is already set.
- [Plugin README](https://github.com/antosha417/nvim-lsp-file-operations): automatic integration instructions and tested-server examples are context, not the chosen loading/integration design.
