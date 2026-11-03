# Proposal

## Why

Neo-tree's clipboard is process-local, so files copied in one Neovim instance cannot be pasted in another. A persistent shared list of source paths enables that workflow and repeated pastes without copying again.

## What Changes

- Persist filesystem copy selections as absolute paths in one state file shared by Neovim processes using this configuration.
- Read the latest shared selection whenever paste runs, including in processes started before the copy.
- Preserve the shared state after paste, cancellation, errors, and process exit. Only a new file-copy action replaces the saved selection; it replaces rather than appends.
- Support copying one entry or a visual selection, including directories.
- Keep existing `c` / `p` keys and Neo-tree's destination and collision handling.
- Keep cut operations local and preserve their move behavior; path-text yanks do not change the shared file clipboard.

## Capabilities

### New Capabilities

- `neotree-shared-clipboard`: Persistent file-copy selections and repeatable paste across Neovim processes.

### Modified Capabilities

None. There are no published specs. The pending `file-tree-viewer-controls` change describes Esc clearing the local clipboard; this proposal leaves local clearing intact but explicitly preserves the shared file.

## Impact

- Update filesystem commands in `lua/configs/neotree.lua` and add a focused helper under `lua/utils/`.
- Add a runtime JSON state file under the configured `stdpath("data")`; no plugin fork, dependency, or lockfile update.
- Adapt to installed Neo-tree clipboard entries and visual command dispatch without editing installed plugin files.
- Scope is same-machine processes sharing this configuration; Ranger, Oil, other sources, remote synchronization, and shared cut state are excluded.
