# Verification

## Mixed-layer regression iteration

Added `tests/minidiff_layers.lua` and observed these failures before fixing them:

- Ordinary source text containing Git's binary/unmerged diagnostic phrases disabled staged hunks.
- Navigation during the text-change debounce missed a newly edited unsaved hunk.
- Switching buffers restarted unchanged Git reads and introduced avoidable loading cycles.
- A successful staged read exposed ready data before projected navigation anchors existed.
- A staged callback arriving after an index-read failure could restore ready staged data using the old index reference.
- Untracked files and new unsaved files lacked an empty index baseline and could not be navigated.

Fixes keep the existing hunk controls and mutation boundaries. Explicit navigation
settles queued local computation synchronously but never waits for Git reads or
replays a blocked jump. Staged readiness now includes projection completion and
both reference-read outcomes. Git watchers and focus refresh remain active;
ordinary buffer switches no longer force a new loading cycle.

Missing index references are classified before using an empty baseline. Ignored
files and unmerged index entries are not treated as new additions. New named
buffers can attach before their file is first written.

The new suite covers saved unstaged edits plus separate unsaved edits alongside
staged edits; staging the saved state without saving the buffer; both callback
orders; failed index reads; no deferred navigation; untracked/new unsaved files;
ignored files; and insertion/deletion/replacement projection boundaries.

## Passed

- `nvim --headless -u NONE -l tests/minidiff_layers.lua`
- `nvim --headless -u NONE -l tests/minidiff_staged.lua`
  - Independent staged snapshots retain index-coordinate hunks and projected buffer anchors.
  - Whole-file staging leaves distinct markers and navigation targets with zero unstaged hunks.
  - Existing mappings and navigation repeat reach staged targets.
  - Unsaved insertions shift anchors. Reverse edits preserve staged hunks. Removed spans stay reachable.
  - Overlapping layers use mixed markers and deduplicated navigation stops.
  - Combined counts and final-target handoff agree with navigation.
  - Staged-only actions preserve buffer and index. Unstaged reset leaves the index intact.
  - Stage, unstage, commit, soft reset, branch switching, whole-file deletion, and unborn HEAD refresh correctly.
  - Linked worktrees refresh across commits and soft reset with automatic reflog creation disabled.
  - Obsolete callbacks are ignored. Failed reads clear staged snapshot hunks. Disable prevents late callbacks from reattaching.
  - Binary and unmerged patch results are rejected with explicit reasons.
- `nvim --headless -u NONE -l tests/minidiff_feedback.lua`
  - Existing lifecycle, feedback, reset, preview, selection, overlay, review handoff, and native diff-navigation checks pass.
  - Updated the reference-read mock for the additive staged read and corrected its outdated feedback module import.

## Pending

- Visual inspection under the configured light and dark themes. Headless checks verify glyphs and highlight groups but not visual contrast in the configured statuscolumn.
- The configured attached-UI regression script was not run because `pynvim` is unavailable in the current Python environment.
