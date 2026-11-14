# Verification

## Automated checks

- `nvim --headless -u NONE -l tests/minidiff_feedback.lua` — passed (`minidiff feedback: all checks passed`). Covers lifecycle transitions, failures, empty references, source fallback, obsolete reference callbacks, disable/reload, blocked actions without replay, notification keys, rendering, ready hunk operations, review protections, overlay preference, and native diff navigation.
- `data/mason/bin/stylua --check moonshine.nvim/diff_tools/lua/moonshine/diff/init.lua moonshine.nvim/diff_tools/lua/moonshine/diff/hunks.lua moonshine.nvim/diff_tools/lua/moonshine/diff/feedback.lua tests/minidiff_feedback.lua` — passed.
- The modified Git-reference helper block in `mini/diff.lua` also passed a range-limited StyLua check with the surrounding upstream style (`AutoPreferSingle`, parentheses, 120 columns, collapsed simple statements). The headless suite loads and exercises the modified engine; the rest of this upstream-style file was not reformatted.
- `git diff --check` — passed.
- `/home/dmitry/.local/bin/openspec validate improve-minidiff-progress-feedback --strict` — passed.

## Configured UI smoke test

`uv run --with pynvim python tests/minidiff_feedback_ui.py` — passed (`minidiff feedback: configured UI smoke checks passed`).

The test starts the real configured Neovim with an attached 120×40 UI and a disposable Git index. Delayed reference callbacks make pending states observable. It checks initial loading, visible notification replacement without stacking, ready navigation and locked hunk preview, external index updates changing updating → ready, a clean tracked file, and an unavailable untracked reference. The test adds no project runtime dependencies and does not stage or modify files in this repository.

Synchronous diff computation still blocks UI painting; no animation or percentage is claimed. Staged diff remains out of scope.
