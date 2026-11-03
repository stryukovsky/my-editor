# Existing language integration map

Reviewed working tree: 2026-11-03. Paths below are relative to the repository
root. Read the current implementation before changing it. This is an inventory
for consolidation, not an already implemented registry.

## Main consumers

| Area | Current owners | Material behavior |
| --- | --- | --- |
| Formatting | `lua/configs/conform.lua`, `lua/plugins/core.lua`, `lua/mappings/inspection.lua` | Conform receives its options through the plugin spec; format-on-save is commented out. Keep formatter ordering and custom options. |
| LSP | `lua/configs/lspconfig.lua`, `lua/plugins/mason.lua` | Native `vim.lsp.config` / `enable`; wrappers around start/attach skip disabled, big-file and review buffers. |
| LSP controls | `moonshine.nvim/lsp-riced/lua/lsp-riced/`, `lua/configs/lsp-riced.lua`, `lua/mappings/lsp_controls.lua` | Inspect server discovery/start/stop paths and their use of `configs.lspconfig.servers` when changing registry ownership. `lua/configs/lsp_controls.lua` is a compatibility facade. |
| Tools | `lua/configs/mason.lua`, `lua/plugins/mason.lua`, `lua/options.lua`, `README.md` | Mason root and PATH are `data/mason`; README contains a manual MasonInstall list, not automatic synchronization. No Mason bridge plugin specs. |
| DAP | `lua/configs/debuggers.lua`, `lua/mappings/dap.lua`, specialist modules below | Shared JS and CodeLLDB adapters, language launch configurations and global envFile normalization. |
| Debug UI/policy | `lua/configs/debug_output.lua`, `moonshine.nvim/debug_output/lua/debug_output/`, `lua/integrations/trouble/sources/dap_breakpoints.lua` | Shared runtime/debug output behavior; retain adapter compatibility when moving definitions. |
| Native completion | `lua/configs/completion.lua`, `moonshine.nvim/native_completion/lua/native_completion/` | Native LSP autotrigger, ranking, midword handling, native snippets and word fallback. `integration.lua` owns LspAttach and mappings; `languages.lua` loads grammar JSON from runtimepath. |
| Completion data | `moonshine.nvim/native_completion/lua/native_completion/languages/*.json`, its `README.md`, `schemas/native-completion-language.schema.json` | Per-grammar context rules and executable fixtures; TSX extends TypeScript and C++ extends C. Changing paths requires updating discovery and schema links. |
| Snippets | `lua/configs/luasnip.lua`, `lua/plugins/core.lua`, `lua/mappings/snippet.lua`, `snippets/http.json` | friendly-snippets plus VS Code/SnipMate/Lua loaders. Local VS Code loading points at `snippets/`; that directory currently has no package.json manifest. Navigation bindings use `vim.snippet`, not LuaSnip. Verify local snippets are actually discovered. |
| Split/join | `lua/configs/treesj.lua`, `lua/mappings/treesj.lua` | Built-in TreeSJ presets plus custom Solidity and Scala node rules. Default maps disabled; recursive split and normal join bindings. |
| Sibling swap | `lua/configs/siblingswap.lua`, `lua/mappings/siblingswap.lua` | Generic parser-based operations; no local language table. Plugin accepts per-language `fallback` rules; do not add registrations for generic support. Current setup lets plugin create mappings internally. |
| Parsing | `lua/configs/treesitter.lua`, `lua/options.lua`, `moonshine.nvim/bigfiles/lua/moonshine/bigfiles/init.lua` | New nvim-treesitter API, parser queue, dependency recursion, persisted statuses, FileType best-effort installs, fold/indent setup and guards. |

## Current explicit choices

### Formatters

`lua → stylua`; `css/html/json/jsonc/typescript/javascript → prettier`;
`markdown → prettier_markdown`; `scala → scalafmt`; `go → gofumpt`;
`rust → rustfmt`; `python → black`; `xml → xmlformatter`;
`solidity → forge_fmt`.

`prettier_markdown` calls prettier with Markdown parser, print width 80, and
prose wrapping enabled. `forge_fmt` runs `forge fmt $FILENAME` without stdin.
React filetypes are not explicitly listed; do not assume the TypeScript entry
covers `typescriptreact` automatically. AGENTS.md's Solidity prettier description
is stale relative to the actual Forge configuration.

### LSP

Explicit enabled list: `html`, `cssls`, `ts_ls`, `lua_ls`, `sqls`, `bashls`,
`basedpyright`, `gopls`, `clangd`, `forge`, `texlab`, `jdtls`, `move_analyzer`,
`jsonls`.

- clangd filetypes: c/cpp/objc/objcpp/cuda.
- gopls filetypes: go/gomod/gowork.
- Forge: `forge lsp --stdio`, Solidity, roots foundry.toml/.git.
- jdtls: bundles Java debug adapter jars from Mason. nvim-jdtls is installed;
  inspect its actual callers before transferring Java lifecycle ownership.
- jsonls: validation with local DAP schema, formatter provider disabled.
- Rust server ownership belongs to rustaceanvim; Scala to opt-in Metals.
  Avoid enabling another generic rust_analyzer/metals client alongside them.

### Debuggers and specialists

| Language family | Current integration / prerequisites |
| --- | --- |
| JS/TS | `configs.debuggers`: server adapter shared by node and pwa-node; executable js-debug-adapter; distinct JS/TS launch lists, TS uses ts-node/npm. |
| C/C++ | `configs.debuggers`: CodeLLDB server at 127.0.0.1, executable prompt, attach uses pid; C reuses C++ configurations. |
| Go | nvim-dap-go plugin config; inspect plugin-generated configurations and Delve executable resolution. |
| Python | `moonshine.nvim/python_tools/lua/moonshine/python/init.lua`: manual setup from `<leader>py`, searches project .venv/venv, otherwise prompts. Configures dap-python with chosen interpreter, installs debugpy through that interpreter's pip, updates basedpyright/pyright settings. Import alone must not run setup. |
| Scala/sbt | `moonshine.nvim/scala_tools/lua/moonshine/scalametals/init.lua`: explicit enable, attaches current and existing eligible buffers, on_attach sets up DAP and Scala configurations. Preserves METALS_JAVA_OPTS/COURSIER_CREDENTIALS. Current configurations lack cwd; migration must add it. |
| Rust | rustaceanvim spec in `lua/plugins/mason.lua`; `after/ftplugin/rust.lua` overrides hover actions. Existing direct vim.keymap.set violates the map-wrapper convention; do not reproduce it. |
| Java | jdtls debug bundle in LSP config; Java DAP launch template exists. Installed plugins/templates alone do not prove a working adapter/session. |

`configs.debuggers` has separate policy sets: node/pwa-node/codelldb/lldb drop
missing envFile paths, while go/java fold env files into env with explicit env
entries winning. Preserve unresolved-variable behavior and path expansion.

`templates/index.json` registers Python, Python command, Node, Go, Java, C++ DAP
templates targeting `.vscode/launch.json`. Actual destinations here are relative
despite AGENTS.md's absolute-path description. Inspect
`moonshine.nvim/templates/lua/moonshine/templates/init.lua` for resolution.
DAP templates merge configurations by name; other templates append on repeat.
`schemas/launch.json` is sourced from debugger configurationAttributes and used
for launch.json / *-dap.json completion through jsonls. Never invent debugger
properties from the protocol alone. Omit console and set cwd on new/migrated
configurations and templates.

### Completion and snippets

Blink and blink.compat are explicitly disabled in `lua/plugins/core.lua`.
Active grammar mappings: c, cpp, go, java, lua, python, rust, scala, solidity,
tsx, typescript. Generic native completion still works without these mappings.
Mappings affect ranking/context, not installation or LSP configuration.
The loader caches mappings, validates inheritance and queries, and fails one
mapping without disabling the others. Preserve that behavior if moving assets.

Read the mapping README and schema before authoring node rules. Fixtures must
cover real node/field names plus neutral contexts. Existing verification:

```sh
nvim --headless -u NONE -i NONE -l tests/native_completion_languages.lua
nvim --headless -u NONE -i NONE -l tests/native_completion.lua
uv run --with pynvim python tests/native_completion_integration.py
```

The mapping suite requires parsers; optional live-server tests cover Lua,
TypeScript and Go. There are additional input, midword and typing suites under
`tests/`; choose them only when touching those behaviors. AGENTS.md's statement
that the repository has no tests is stale.

### Tree-sitter

Declared initial parsers: c, cpp, rust, zig, java, kotlin, scala, clojure,
javascript, typescript, tsx, html, css, scss, python, go, lua, bash, vim, haskell,
ocaml, fsharp, elixir, json, yaml, toml, xml, ini, nix, markdown, markdown_inline,
latex, rst, dockerfile, cmake, make, gitignore, gitattributes, git_rebase, sql,
regex, comment, todotxt, csv, diff. Solidity is absent from this initial list
despite its other integrations; FileType can still request its parser.

Installation root: `data/tree-sitter`. `auto-install.json` becomes the parser
list after initial creation. States: pending/installed/failed. Install logic
recurses `requires`, skips unavailable and tier-4 parsers, queues one install
at a time, and avoids repeated attempts in one session. Language registry
reconciliation must work for users with an existing manifest, not just fresh
installs. Keep user additions; do not use runtime status as the sole desired
language catalogue. Parser association and injection queries need checking for
aliases and embedded languages. No root queries/ or lsp/ directory was present.

## Adjacent language data and generic integrations

| Area | Sources / implications |
| --- | --- |
| Testing | `lua/configs/neotest.lua`, `lua/plugins/mason.lua`: Forge local adapter, Go, rustaceanvim, Python, Scala (sbt/scalatest), Jest (npm test --). Preserve adapter factories/options and dependency load timing. Local Forge adapter: `moonshine.nvim/neotest-forge/lua/neotest-forge/`. |
| Refactoring | `lua/configs/refactoring-setup.lua`: language-specific return/parameter prompts; `lua/mappings/refactoring-setup.lua`. Read `lua/mappings/init.lua` to verify these modules are loaded before assuming setup is active. |
| Comments | `lua/configs/comment.lua`: Solidity line/block overrides; sh/bash/zsh/env/dotenv hash comments and pre_hook. |
| Search fallback | `moonshine.nvim/ripgreplsp/lua/moonshine/ripgreplsp/init.lua`: FT_TO_LANG ast-grep aliases plus language-specific definition patterns; ast-grep executable lookup and rg fallback. This catalogue is distinct from Tree-sitter grammar names. |
| Spell | `lua/options.lua` and `moonshine.nvim/bigfiles/lua/moonshine/bigfiles/init.lua` duplicate ft_string_groups. Preserve spell exclusions and existing buffer guards while moving shared data. Strict grammar module adjusts highlights, not language tooling. |
| Filetype detection | `lua/options.lua`: todo.todotxt/done.todotxt → todotxt; launch.json → jsonc. Rust ftplugin is separate. New aliases require actual detection, not only registry metadata. |
| Folding/indent | `lua/options.lua`: Tree-sitter foldexpr/indentexpr, >10000 lines or >10KB guard. Bigfiles module has a separate 100KB/10000-line heuristic and user skip flag. Preserve both. |
| Rainbow | `lua/configs/rainbow_delimiters.lua`: generic grammar queries, disabled at >=5000 lines or big-file skip. No per-language local registration. |
| Scalar selection | `moonshine.nvim/scalar_lines/lua/scalar_lines/`, `lua/configs/scalar_lines.lua`: generic syntax operations, inspect only if a grammar exposes a real incompatibility. |
| Tasks | `lua/configs/overseer.lua`, `moonshine.nvim/overseer_extensions/lua/overseer/template/uv.lua`, `moonshine.nvim/overseer_extensions/lua/moonshine/tasks/init.lua`: project/task discovery, including Python uv. Avoid turning project task history into language registry data. |
| Markup/data tools | `lua/configs/render-markdown.lua`, `lua/configs/markdown-preview.lua`, `moonshine.nvim/markdown_tools/`, `lua/configs/csv.lua`, `lua/configs/todotxt.lua`: specialized filetype behavior; migrate language declarations only when needed, retain runtime/UI ownership. |
| Generic LSP UI | diagnostics, lspeek, Trouble, illuminate, Telescope, symbols, lsp-riced: use attached client capabilities; do not duplicate per-language registrations. |

## Load order and inspection

`init.lua` patches stdpath(data) to config/data, bootstraps Lazy, loads options →
configs → mappings → theme. Local features are eagerly registered by directory.
`configs/init.lua` loads Tree-sitter, LuaSnip and neotest before LSP/completion;
debuggers load later. Conform options are evaluated by its Lazy plugin spec,
not explicitly by configs/init. A registry must be safe to read before optional
plugins are loaded: defer plugin requires and setup side effects.

Installed implementation examples to inspect without modifying:

- `data/lazy/mason.nvim/lua/mason-registry/init.lua`: package specs, refresh,
  package availability and installation APIs.
- `data/mason/registries/github/mason-org/mason-registry/registry.json`: cached
  package specs; also check info.json for registry version information.
- `data/lazy/treesj/lua/treesj/langs/`: shipped language presets.
- `data/lazy/sibling-swap.nvim/lua/sibling-swap/settings.lua`: generic separators,
  per-language fallback contract and default-map behavior.
- `data/lazy/nvim-lspconfig/lsp/`, `data/lazy/conform.nvim/lua/conform/formatters/`:
  exact consumer IDs and executable/options defaults.

Do not treat installed data/ contents as versioned configuration or edit them to
implement language support. Keep tool selection explicit in the unified source.
