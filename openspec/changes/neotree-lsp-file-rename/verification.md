## Result

Implemented the edited tasks on 2026-11-12. Filesystem `r` gathers connected
project clients: multiple clients open a Telescope multi-select picker. No client,
unsupported selected clients, and nonmatching paths require a default-No Yes/No
confirmation before filesystem rename. Only selected clients receive methods
matching their advertised capability filters.

The implementation uses the fork's native `filesystem/lib/lsp_rename.lua`, with
no file-operations plugin or compatibility patches. It does not replace global
client discovery or install global mappings. Existing
`<leader>rn` and document-symbol rename bindings remain unchanged.

## Evidence

- Disposable headless integration fixture: **53 checks passed** using actual
  Neo-tree filesystem actions, Telescope picker actions, and native rename hooks,
  with controlled LSP clients and input responses.
- **11 persistent fork tests passed** for protocol dispatch, method-specific glob
  filters, URI schemes, case sensitivity, folder-only notifications after source
  removal, selected/running clients, timeout/protocol/transport errors, null edits,
  edit failures, failed notifications, and unsaved workspace edits.
- Targeted confirmation fixture passed for no client, all unsupported inventory
  clients, Yes/No/cancel responses, supporting clients, and nonmatching filters.
- Covered zero/one/multiple clients, two-of-three selection, unselected-client
  exclusion, project boundaries, unsupported and nonmatching providers,
  cancellation at both prompts, destination collisions, no-op names, pre/post
  operation ordering, unsaved workspace edits, injected disk failures, hook
  failures, and modified buffers inside renamed directories.
- Real installed TypeScript language server: renaming `old.ts` to `new.ts`
  changed a reference in `main.ts` from `./old` to `./new`. Its reference buffer
  remained modified and its disk contents remained unchanged until save.
- Full configuration startup passed, including named server capabilities,
  rustaceanvim capability configuration, unrelated gopls configuration, lazy
  native module loading, absence of `:LFO`, absence of the removed dependency from
  lazy specs and runtimepath, and absence of both patch files.
- StyLua checks passed for the native module, its tests, and the config helper; full startup
  also loaded the edited Lua configuration successfully.
- `git diff --check` passed. OpenSpec validation passed in the initial apply;
  it could not be rerun for this transition because `openspec` is not on PATH.

Fixtures were run under `/tmp/opencode/` and `/tmp/neotree-lsp-research/` with
disposable project files. Persistent tests use the fork's existing Plenary suite;
no test framework was added to the config repository.

## Reproducibility and limitations

- Neo-tree callbacks are committed to the existing fork branch
  `option-consider-untracked-as-git-change` in `9f5594b`; the local Neo-tree patch
  and build hook were removed. The same 53 integration checks plus targeted
  unsupported-client Yes/No/cancel checks passed after this transition.
- The fork now also owns the focused LSP rename module in `3ebc196` (116 lines,
  plus 11 persistent tests). The file-operations
  dependency, its lazy spec, patch helper, and remaining patch were removed.
- `lazy-lock.json` originally contained only an opening brace. The package
  manager regenerated valid pins from installed plugin checkouts; the native
  transition updates the fork pin and removes the dependency via lazy.nvim.
- LSP pre-rename processing uses a 10000 ms timeout and warns on errors, retaining
  best-effort filesystem rename behavior. Only static capability filters are used;
  dynamic-only registrations remain outside the current implementation.
  Workspace edits are not transactionally rolled back if the later disk rename
  fails. No real Java/Rust/Python refactoring project was exercised in this apply;
  their support evidence is in server-support.md.
