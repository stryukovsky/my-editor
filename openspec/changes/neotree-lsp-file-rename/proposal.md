## Why

Renaming a file in Neo-tree should let language servers update imports and
references. The integration must be explicitly selected by Neo-tree configuration,
without automatic file-operation subscriptions or global rename replacements.

## What Changes

- Connect filesystem `r` to `nvim-lsp-file-operations` through an explicit
  command configured in this repository's Neo-tree setup.
- Add a small opt-in rename callback seam to `stryukovsky/neo-tree.nvim`, preserving
  its prompt, safety checks, filesystem operation, buffer handling, and refresh.
- Call the plugin's before/after rename APIs directly; do not use its automatic
  integration setup or impose its README's tree-plugin loading order.
- Advertise rename client capabilities only for explicitly configured supporting
  servers, before those clients start.
- Use ordinary rename with no connected project client, use one client directly,
  and show a multi-select recipient picker when multiple clients are connected.
- Document rename-method support for every language server in README's
  `MasonInstall` command, distinguishing file rename from symbol rename.

## Capabilities

### Modified Capabilities

- `file-tree-viewer`: extend filesystem `r` with optional LSP rename assistance
  and define its isolation and fallback behavior.

## Impact

Planned implementation touches `lua/configs/neotree.lua`, a helper under
`lua/integrations/`, plugin declarations, selected server configurations, and the
Neo-tree fork's rename path. A new plugin dependency is required. Update pins only
through lazy.nvim. Tracked compatibility patches keep the fork callback seam and
explicit plugin recipient argument reproducible.

Other Neo-tree sources, `<leader>rn`, cut/paste moves, Oil, Ranger, create/delete,
global keymaps, and global LSP defaults are outside this change.
