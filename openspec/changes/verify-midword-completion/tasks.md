# Tasks

## 1. Establish the native and configured acceptance matrix

- [x] 1.1 Add reusable fake-LSP cases and explicit cursor placement for `pri|nt(value)`, `|print(value)`, and `pri|Other` without explicit edit ranges. Assert exact accepted text and byte cursor position for native control and configured completion; record commands and actual Neovim version in `verification.md`.
- [x] 1.2 Add full-word and cursor-ended `TextEdit` cases, differing insert/replace ranges, and inherited list edit ranges. Assert exact output for each selected range, document the native insert/replace policy in `verification.md`, and prove text outside explicit ranges is retained.
- [x] 1.3 Add full-word snippet replacement for `cal|l;`, placeholder editing, and the existing jump to `$0`. Assert one expansion, active placeholder state, and final `call(item)|;`; record native/configured results.
- [x] 1.4 Add Cyrillic plain-suffix completion and UTF-8/UTF-16 range cases with Cyrillic and emoji before the edit. Assert valid complete characters, unchanged surrounding text, and exact cursor byte positions; record results in the same matrix.
- [x] 1.5 Add selected-item cancellation, import/command exactly-once checks, standard and explicit-first-item acceptance keys, and isolated undo checks. Verify original text after cancellation/undo and record the baseline undo sequence rather than assuming a fresh undo boundary.

## 2. Correct only demonstrated failures

- [x] 2.1 Classify each failed matrix case against the native control and identify the responsible layer. Deliver a concise diagnosis in `verification.md`; if all cases pass, explicitly record that no production correction is needed and mark the conditional correction task not needed with evidence.
- [x] 2.2 Only for a demonstrated gap, implement the narrowest correction through supported native facilities or a guarded config helper. Re-run each failing reproducer plus its surrounding-text and Unicode controls. If private hooks or a runtime patch would be required, document the limitation and leave this task unresolved rather than expand scope. If no failures exist, complete this task by recording that it was not needed.
- [x] 2.3 Document the verified behavior, explicit-range precedence, native insert/replace choice, and tested Neovim version in README. Verify every documented example against the acceptance matrix and include any unresolved runtime limitation.

## 3. Verify integration and stop

- [x] 3.1 Run `nvim --headless -u NONE -i NONE -l tests/native_completion.lua`, `uv run --with pynvim python tests/native_completion_integration.py`, and the focused fixture if separate. If production acceptance changes, also run `uv run --with pynvim python tests/native_input_completion.py` and `nvim --headless -u NONE -i NONE -l tests/input_completion.lua`. Record results; confirm ranking, imports, snippets, terminal insertion, and gitcommit file/folder acceptance retain their existing behavior.
- [x] 3.2 Run formatting checks for changed Lua files, `git diff --check`, and `openspec validate verify-midword-completion --strict --no-interactive`. Review the diff against the spec and confirm no unrelated completion source, dependency, keymap policy, or runtime code changed. Complete the change only when every required matrix case passes.
