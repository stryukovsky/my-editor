# Verification

## Passed

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
