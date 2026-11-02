# Proposal

## Why

Neo-tree's Git status view opens submodule paths as folders instead of showing their Git state. Its current status collection loses submodule details and can omit dirty submodules, making changes difficult to inspect reliably.

## What Changes

- In the Git status source only, make `<CR>` on a submodule open a read-only state view rather than its directory.
- Show the superproject HEAD gitlink, staged gitlink, checked-out submodule commit hashes, and tracked/untracked dirtiness, with explicit labels for unavailable values.
- Detect changed gitlinks, tracked modifications, and untracked content independently, including combinations, and place entries correctly in Staged and Unstaged sections.
- Make submodule change detection explicit rather than allowing Git's submodule ignore settings to silently hide changes in this source.
- Refresh state after external changes and handle missing, uninitialized, deleted, and conflicted submodules without opening a folder or showing stale hashes.
- Preserve normal filesystem-source directory navigation and existing behavior for ordinary Git status entries.

## Capabilities

### New Capabilities

- `neotree-git-submodules`: Submodule change detection, staged/unstaged presentation, and state inspection from Neo-tree's Git status source.

### Modified Capabilities

None. No published specifications exist. The pending `file-tree-viewer-controls` change covers filesystem navigation, which this proposal preserves.

## Impact

- Update `lua/configs/neotree_git_groups.lua` for structured status and gitlink metadata, and `lua/configs/neotree.lua` for a Git-status-only open command.
- Add a focused helper for submodule state collection and display; reuse `lua/configs/gitutils.lua` where appropriate.
- Keep implementation in tracked configuration files; no installed-plugin edits, new dependencies, or manual lockfile changes.
- Exclude new submodule management commands, recursive child-file browsing in the parent status tree, and changes to staging/revert semantics.
