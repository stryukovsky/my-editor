# Show staged MiniDiff hunks

## Why

MiniDiff currently compares the buffer against the Git index, so staging a
change removes its markers and navigation targets. Staged changes should remain
visible and reachable without hiding unstaged changes.

## Changes

Implementation priority: independent staged snapshots and fully staged files.
Mixed-file navigation reuses existing controls without extra modes or filters.

- Show staged (HEAD → index) and unstaged (index → buffer) hunks together in
  ordinary Git-backed buffers.
- Distinguish staged, unstaged, and overlapping changes in the existing gutter,
  including under both light and dark themes.
- Make existing `]g` and `[g` mappings and navigation repeat traverse both kinds
  in buffer order without duplicate stops at the same location.
- Project staged locations into current buffer coordinates, including unsaved
  edits and deleted lines.
- Make the existing hunk position/count display agree with navigation targets.
- Refresh staged results after index changes, commits, and branch changes
  without reopening the buffer.
- Preserve unstaged reset, selection, preview, and overlay semantics.
  Staged-only targets report that these actions do not apply rather than
  modifying the index or displaying an unrelated hunk.

## Acceptance

- A fully staged modified file still has distinct markers and reachable hunks
  while its unstaged diff is empty.
- A partly staged file shows both layers. Existing navigation visits their
  ordered union, with repeat and backward wrapping preserved.
- Forward navigation focuses Neo-tree Git status only after the final combined
  target, not after the final unstaged target.
- Overlapping staged and unstaged locations show a mixed marker and produce one
  navigation stop at a shared location.
- Insertions and deletions between the index and buffer shift staged targets
  correctly. Fully removed staged spans remain reachable at a valid nearby line.
- Staged additions work before the repository's first commit. Clean files do not
  show staged markers.
- Stage, unstage, commit, and branch changes update results without stale
  callbacks restoring older markers. Pending or failed staged reads are not
  reported as a clean staged diff.
- Existing unstaged actions remain unchanged. Reset never unstages a change.
  Review/history buffers and native diff-window navigation retain their current
  behavior.
- Focused headless regression checks and a light/dark gutter check demonstrate
  these outcomes.

## Out of scope

- Staging or unstaging individual hunks.
- Staged hunk previews, staged textobjects, or staged inline overlays.
- New mappings, navigation filters, or a staged/unstaged mode switch.
- Repository-wide hunk navigation or changes to review/history comparisons.
- Displaying files with no open text buffer, binary diffs, or resolving unmerged
  index entries.
