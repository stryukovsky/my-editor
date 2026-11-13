# jumper.nvim

One persistent lowercase mark (`a`–`z`) per name across all files. Marks are
stored in `stdpath("data")/jumper-marks.json` (this config redirects `stdpath`
to `~/.config/nvim/data/`). Mark letters appear beside other status-column
signs.

| Keys/command | Action |
| --- | --- |
| `m{a-z}` | Set or move a mark |
| `'{a-z}` | Jump to a mark, including in another file |
| `]m` / `[m` | Next/previous assigned name alphabetically (counts and wrap supported) |
| `]]` / `[[` | Repeat the latest navigation forward/backward |
| `;` / `<A-;>`, `n` / `N` | Existing forward/backward navigation repeat |
| `dm` / `<leader>dm` | Delete marks on this line / in this file |
| `:JumperDelete p` | Delete mark `p` |
| `<leader>maa` | Add the next unused letter after the highest assigned mark (wraps after `z`) |
| `<leader>mad` | Delete all global marks |

`<leader>ma` opens the Marks group in WhichKey. Auto-add starts with `a` when
there are no marks; if all 26 letters are occupied, it leaves them unchanged.

Lowercase native marks are not imported: old buffer-local marks can conflict,
and this plugin owns the mapped lowercase mark operations. Native uppercase
marks and `''` remain available; `]]`/`[[` replace native section motions.
Locations follow edits while files are loaded. Changes made while a file is
unloaded cannot be tracked; saved coordinates are clamped when it is reopened.
Concurrent Neovim instances do not merge mark-store writes.
