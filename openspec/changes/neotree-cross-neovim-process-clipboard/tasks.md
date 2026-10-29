# Tasks

## 1. Shared storage

- [x] 1.1 Add `lua/utils/neotree_clipboard.lua` with lazy data-path resolution, versioned JSON validation, and atomic replacement using unique sibling temporary files; verify through headless Neovim with temporary state paths that paths containing spaces/newlines round-trip and failed publication preserves the old file.
- [x] 1.2 Handle missing, empty, unreadable, malformed, and unsupported state with distinct user-facing outcomes; verify these cases with temporary fixtures and confirm none modifies the saved file.

## 2. Filesystem copy and paste integration

- [x] 2.1 Override filesystem normal and visual copy commands in `lua/configs/neotree.lua`; collect valid absolute paths, replace the whole shared selection once per action, and update local marks only after successful publication. Verify single-entry, visual file/directory, repeated-same-entry, empty-selection, and failed-write behavior against the installed Neo-tree dispatch.
- [x] 2.2 Override filesystem paste to read fresh shared paths and adapt them to a per-invocation native copy clipboard, retaining native destination resolution, collision prompts, and refresh callbacks. Verify recursive directory copying, missing-source reporting, destination conflicts, and cancellation without changing the state file.
- [x] 2.3 Preserve native local cut precedence and keep Esc, clear, text yanks, and other sources independent from shared storage. Verify cut still moves files, later paste returns to saved copies, and asynchronous paste completion does not overwrite a newer copy/cut selection.
- [x] 2.4 Document copy replacement, the state-file location, repeated paste, local cut precedence, and Esc behavior in the existing Neo-tree documentation section (or add a concise README section); verify the documented keys match the configuration and run StyLua checks on changed Lua files.

## 3. Cross-process integration verification

- [x] 3.1 Use two Neovim processes with separate working directories and temporary source/destination trees: copy in A, paste twice in B, then copy in B and paste in A. Verify destination contents, intact sources, latest-copy replacement, and unchanged state bytes after each paste.
- [x] 3.2 Exit the copying process and paste from a newly started process; verify persistence. Publish competing copy selections from two processes and verify the resulting JSON contains one complete selection, with no partial writes or leaked temporary files.
- [x] 3.3 Review the implementation against every spec scenario and record manual/headless verification outcomes without adding a permanent test framework; verify no plugin files or lockfile were edited and no new direct keymaps bypass `mappings.map`.
