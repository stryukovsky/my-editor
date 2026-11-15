## Findings

Implementation belongs in the installed fork at
`data/lazy/neo-tree.nvim/lua/neo-tree/sources/git_status/lib/items.lua`.
`M.render` populates `state.default_expanded_nodes` with every generated
directory ID on every scan. The shared renderer combines those defaults with
the previous tree's expanded IDs before drawing. Therefore a deliberately
closed directory is expanded again on refresh. IDs include the section and
path, so an entry moving from Unstaged to Staged correctly gets a new ID.

The source already has `preserve_selection`: it prefers the same ID, then the
next surviving sibling, then later visible rows, and finally earlier rows.
Stage actions are queued in `lib/actions.lua` and trigger one Git refresh
after the burst. Refresh can also come from Git events or index watching.

## Approach

Use initial expansion only when the Git-status tree has no prior shape.
On subsequent renders, let the renderer restore surviving expanded IDs.
Keep both section roots visible, but do not automatically expand newly
appearing descendants. The renderer normally forces its first root open when
restoring expansion; allow Git-status refreshes to retain a closed Unstaged root
without changing the shared renderer's behavior for other sources.

Keep selection anchored to the original section and tree order when its ID
disappears. Prefer the next surviving sibling, then the next visible row
across section boundaries; use the prior visible row only at the end. Do not
focus the moved entry in its new section instead of advancing. Confirm this
against the existing selection logic before changing it. Preserve selection
by ID when the selected entry survives a refresh.

Check the first display, repeated scans, both staging directions, staging a
folder with multiple children, and quick queued actions using a disposable
Git repository. No configuration change or `lazy-lock.json` edit is needed.
