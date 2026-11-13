# Proposal

## Why

Neovim's lowercase marks are buffer-local, so a short mark name cannot be jumped to reliably from another file. The current `marks.nvim` integration also navigates marks by location rather than providing a persistent, alphabetically ordered set of cross-file destinations.

## What Changes

- Add `moonshine.nvim/jumper.nvim` to manage one persistent, global namespace of lowercase `a`–`z` marks across files: `m{letter}` sets or moves a mark and `'{letter}` jumps to it from any file.
- Navigate existing marks alphabetically with `]m` and `[m`, including `]]`/`[[` repeat mappings and integration with the existing `moonshine.utils.navigation_repeat` helper (`;`, `n` and their configured reverse counterparts).
- Display mark letters at their target lines in the existing status-column sign area; keep existing fold, line-number, diff and other sign behavior.
- Replace `marks.nvim` mappings/signs and provide deletion of individual marks and marks for the current file without leaving stale destinations.
- **BREAKING**: lowercase marks cease to be buffer-local, and `]m`/`[m` change from location-based `marks.nvim` navigation to global alphabetical navigation. The `marks.nvim` plugin is removed.

## Capabilities

### New Capabilities

- `persistent-marks`: Persistent cross-file named marks, navigation, deletion, and status-column visibility.

### Modified Capabilities

None.

## Impact

New local plugin under `moonshine.nvim/jumper.nvim/`; replace `lua/configs/marks.lua` and the `chentoast/marks.nvim` spec in `lua/plugins/core.lua`; add configuration/keymaps through `lua/configs/init.lua` and `lua/mappings/init.lua`; integrate with `lua/configs/statuscolumn.lua` and `moonshine.utils.navigation_repeat`. Persist state under this configuration's patched `stdpath("data")` directory. Do not edit `lazy-lock.json` by hand.
