## Why

Staging a file or folder in Neo-tree's Git-status source rebuilds the tree and
reopens folders the user closed. This disrupts the selection while entries move
between Unstaged and Staged.

## Changes

- Expand the Git-status tree by default only when first shown; preserve the
  user's open and closed folders across later status refreshes.
- Keep each surviving folder's expansion state when entries move between
  sections. Keep Unstaged and Staged visible.
- After staging or unstaging removes the selected entry from its section,
  select the next surviving visible item in tree order, preferring a sibling;
  fall back to the nearest prior visible item at the end.
- Preserve the existing sort order and avoid expanding a closed folder merely
  to choose the next item.

## Acceptance

- Close some folders and open others in both sections; stage or unstage a file
  or folder. Surviving folders retain their prior state and the moved entry
  appears in the correct section.
- When the selected entry disappears, focus advances to the next surviving
  visible item, or falls back at the end, without jumping to the moved entry.
- Repeated queued actions and unrelated Git-status refreshes do not reopen
  deliberately closed folders.

## Out of scope

- Changes to Git staging semantics, filesystem-source behavior, or sorting
  configuration.
