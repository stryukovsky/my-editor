# Design

## Context

See proposal.md for motivation. `lua/configs/neotree.lua` maps filesystem `c`, `x`, and `p` to native commands. Installed Neo-tree common commands store entries as `{ action, node }` keyed by node id. Copy toggles entries rather than replacing the selection; visual copy toggles each selected node. Native paste snapshots entries and immediately empties `state.clipboard`, then invokes copy/move actions sequentially. Filesystem wrappers supply redraw and `show_new_children` callbacks.

The data path is overridden by this configuration to `~/.config/nvim/data`. The pending file-tree-viewer-controls spec describes Esc clearing the clipboard; shared storage must remain independent of this local action. No published capability currently owns this behavior.

## Goals / Non-Goals

**Goals:** Keep persistence separate from Neo-tree node objects, read fresh state at paste time, and reuse native filesystem operations and prompts.

**Non-Goals:** Persisting cut operations, live synchronization of clipboard icons, watching the file, modifying Neo-tree internals, or copying file contents at copy time.

## Decisions

### One versioned JSON file, atomically replaced

Add `lua/utils/neotree_clipboard.lua`, resolving `vim.fn.stdpath("data") .. "/neotree-clipboard.json"` lazily. Store `{ "version": 1, "paths": ["/absolute/path"] }`. Paths alone are portable between processes; serializing tree nodes couples storage to UI internals. JSON handles whitespace and newlines in names without shell escaping.

Create the parent directory if needed. Write a uniquely named sibling temporary file, close it, and rename it over the target. Use restrictive file permissions for stored paths. Clean up only the temporary file on failure and preserve the old published state. Concurrent writers use last successful rename wins; no read/merge or locking is necessary because a copy replaces the whole selection. Do not truncate the live file before writing. Do not delete the state file on startup or exit.

### Filesystem command overrides only

Override filesystem `copy_to_clipboard`, `copy_to_clipboard_visual`, and `paste_from_clipboard` through configuration commands while keeping existing key mappings. Register both normal and visual variants so Neo-tree's visual dispatch remains functional. Collect valid filesystem nodes and deduplicate absolute paths before a single publication. A new normal copy is a one-entry replacement; a visual copy is one batch. Do not invoke native toggle-copy to accumulate entries. After publication, replace the local copy selection and redraw using Neo-tree's clipboard event conventions. Ignore message/empty selections without changing storage. On write failure, notify and do not claim success.

Global monkey-patching was rejected because it affects other sources and complicates plugin upgrades. New direct keymaps are unnecessary.

### Read before every shared paste; reuse native operations

If local clipboard entries include an active cut, delegate to native filesystem paste first, preserving move semantics and leaving shared storage untouched. A successful new copy replaces the local selection, so this cut precedence applies only to a cut made after that copy. Otherwise read and validate the shared file on every paste; never fall back to stale local copies after a read error or missing state.

Validate version, path-list shape, and absolute paths before any operation. Treat absent/empty state as nothing to paste; report malformed or unreadable state. Check source existence at paste time, report missing entries, and process remaining valid entries. Reconstruct only the minimal copy-node fields required by installed native paste (`id`, `path`, `name`, and type where needed). Supply a temporary per-invocation clipboard snapshot to the filesystem paste wrapper and let it retain destination resolution, collision prompts, recursive copying, and refresh callbacks. Verify that asynchronous callbacks cannot overwrite a later copy or cut in the live state; keep the operation snapshot isolated where necessary.

Native paste may clear its temporary clipboard; no paste callback writes persistent state. Subsequent paste reloads the saved paths. Reusing native operations avoids reimplementing filesystem conflict handling. Restoring a captured clipboard after asynchronous completion was rejected because it could overwrite a newer user selection.

### Local cancellation stays local

Keep native cut, clear, Esc, and text-yank handling. Shared reads are action-driven, so no watcher or startup import is required. Esc can clear local marks while a later paste still reads the shared copy file. This explicitly qualifies the pending viewer-controls contract for Neo-tree shared copies; Ranger behavior is unaffected.

## Risks / Trade-offs

- [Neo-tree internal node shape or visual dispatch changes] → Keep adaptation in one helper and verify against the installed version; no lockfile edits.
- [Sources change after copying] → Copy current source contents at paste time; report missing sources and retain paths.
- [Two users' copy actions race across processes] → Last completed publication wins, documented by the spec.
- [Partial paste or user cancels a collision prompt] → Preserve saved state unconditionally and retain native interaction.
- [Local cut temporarily hides a shared copy] → Cut has explicit precedence until consumed or cleared; it never modifies shared storage.

## Migration Plan

No migration is required: the file is created on first successful copy. Apply helper and filesystem overrides together. Verify using temporary sources and destinations in two Neovim processes. Roll back the overrides and helper to return to native clipboard behavior; an unused state file can remain without affecting Neo-tree.
