# Tasks

Only the conservative comment slice is scheduled. Optional design-table rows require separate scope selection.

## 1. Native line comments

- [ ] 1.1 Route line-comment mappings through native commenting and mappings.map; disable overlapping Comment.nvim line mappings while retaining blockwise commands. Verify gcc, motion and visual commenting, repeat and undo, plus RU/EN behavior in a configured session.
- [ ] 1.2 Preserve buffer-local Solidity and sh/bash/zsh/env/dotenv comment syntax. Verify comment/uncomment round trips in disposable buffers for every listed filetype.
- [ ] 1.3 Replace the Comment.api dependency in mappings/todo.lua with commentstring-based insertion. Verify TODO placement and cursor position on indented, empty and first lines without modifying the original source line.
- [ ] 1.4 Update README.md and relevant config guidance for native line commenting and retained plugin blockwise commands. Verify documented mappings match effective :verbose map output.

## 2. Integration verification

- [ ] 2.1 Start normal configured Neovim with disposable source files and inspect :messages; verify line/block comments, TODO insertion, native completion, snippet navigation and LSP attachment continue to work.
- [ ] 2.2 Search active config for remaining Comment references and confirm each is intentional; verify plugin remains installed for blockwise commands, lockfile is not manually edited and optional table rows have no implementation changes.
