# Distinguish unstaged edits within staged hunks

## Why

Navigation currently merges overlapping or adjacent staged and unstaged ranges, so a whole-file staged addition can swallow precise unstaged edits into one navigation stop. Rendering also replaces overlapping unstaged signs with mixed signs, obscuring which lines still differ from the index.

## Changes

- Partition overlapping display ranges into staged-only portions and precise effective unstaged hunks. As selected during planning, both staged portions and unstaged hunks remain separate navigation stops.
- Give unstaged changes precedence on overlapping lines and deletion anchors. Render their existing add/change/delete signs in the statuscolumn instead of staged or mixed signs; retain staged signs on the remaining staged-only lines.
- Keep adjacent staged and unstaged segments separate instead of merging across the layer boundary. Preserve existing grouping within the same layer.
- Use the resulting ordered segment list for forward/backward navigation, repeat, current position, hunk counts, and final-target handoff.
- Preserve the original HEAD → index staged snapshot and index → live-buffer effective unstaged snapshot. Splitting is presentation/navigation behavior, not a change to Git comparisons or mutation ranges.

## Acceptance

- A fully staged new file with a later unstaged edit in its middle has separate staged-before, unstaged, and staged-after stops where each portion exists.
- Multiple separated unstaged edits inside a staged addition each remain reachable, with intervening staged portions as separate stops.
- Unstaged insertions above a staged range appear at their actual live-buffer lines and shift the staged locations correctly without merging across the boundary.
- Unstaged additions, replacements, and deletion anchors inside a staged range show unstaged statuscolumn signs. Unaffected staged lines retain staged signs.
- A fully overlapping unstaged edit produces one unstaged stop, not a duplicate staged stop. Zero-line deletions retain a valid reachable anchor.
- `]g`, `[g`, repeat, lualine counts, and final-target handoff agree on the same ordered segment list. Adjacent different-layer stops are visited independently.
- Saved and unsaved edits continue to form the effective index → buffer comparison. Cancelling edits add no false nonstaged targets.
- Reset, preview, and selection still use real effective unstaged hunks, never clipped staged segments. No navigation or drawing operation changes the Git index or buffer text.
- Staged-only files, unstaged-only files, untracked files, overlay toggling, review/history buffers, and native diff windows retain their existing behavior outside the changed overlap/adjacency rules.

## Out of scope

- Changing staging commands, Git baseline acquisition, cache ownership, or asynchronous refresh policy.
- Navigating saved and unsaved changes as independent layers.
- Adding gutter columns, new keymaps, a layer selector, or staged preview/reset support.
- Refactoring the hunk pipeline or changing existing overlay content.
