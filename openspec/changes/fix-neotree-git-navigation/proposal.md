## Why

Neo-tree's next/previous Git change navigation misses untracked files inside
untracked folders and does not reliably follow the expected tree order. The
user wants every eligible changed file reachable without prioritizing shallower
files over nested files.

## What Changes

- Include untracked files alongside tracked changes when untracked navigation
  is enabled, as it already is in this Neovim configuration.
- Discover individual files inside wholly untracked folders, even when those
  folders have never been expanded.
- Make `]g` traverse files in depth-first tree display order and `[g` traverse
  the exact reverse order, revealing collapsed ancestors as needed.
- Preserve wraparound and restrict navigation to the displayed filesystem root.

## Capabilities

### New Capabilities

- `neotree-git-navigation`: complete, deterministic filesystem Git-change navigation.

## Impact

Implement directly in `/home/dmitry/.config/nvim/data/lazy/neo-tree.nvim`.
Likely affected areas are filesystem navigation commands, Git status collection,
and tree ordering helpers. Keep OpenSpec artifacts in this config's `openspec/`
folder. Do not manually edit `lazy-lock.json`.
