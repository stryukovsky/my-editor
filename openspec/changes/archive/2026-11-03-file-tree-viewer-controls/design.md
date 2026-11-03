# Design

## Context

See proposal.md for why this standard exists. Requirements are in `specs/file-tree-viewer/spec.md`.

Neo-tree's filesystem map in `lua/configs/neotree.lua` is already the reference. `go_deep` / `go_shallow` in `lua/utils/neotree_utils.lua` implement descend and ascend. `oo` calls `utils/terminal.lua`, which opens a Kitty tab when `KITTY_LISTEN_ON` is set. `O` calls `utils/system_file_explorer.lua` (Nemo if installed, otherwise Nautilus `--select`, Finder `open -R` on macOS).

Ranger's running config is `~/.config/ranger`. This repo also keeps copies in `setup/fedora/ranger/` and `setup/macos/ranger/`. Nothing in `setup.sh` copies them into `~/.config/ranger`. The running Fedora config is ahead of those copies: `oo` / `L` call `open_in_new_tab` (Kitty). The setup copies still call `open_in_new_window` (Ghostty).

## Goals / Non-Goals

**Goals:**

- Make Ranger bind the shared actions to the Neo-tree keys, including descend through a single-child directory chain.
- Keep one Ranger command implementation, with only trash and the system file manager varying by OS.
- Update the running config and both setup copies together.
- Change Neo-tree only where its current behavior disagrees with the spec.

**Non-Goals:**

- Rebinding Neo-tree keys that already match the spec.
- Teaching Ranger buffers, document symbols, git stage, or in-editor replace.
- Vendoring Ranger inside `lua/` or teaching `setup.sh` a new install path.

## Decisions

### Neo-tree stays the reference; one behavior fix

Most filesystem bindings already match the spec (`l` / Enter, `h`, `a`, `f`, `F`, `c` / `x` / `p`, `y`, `P`, `e`, `m`, `i`, `s`, `u`, `R`, `S`, `w` / `W` / `C`). Apply does not reorder that map.

`oo` currently passes the selected path through as the tab working directory, including when the selection is a file. The spec requires the parent directory for a file. Apply changes that command to use the parent when the node is a file, which is what `open_new_terminal` already does. The key stays `oo`.

Alternative considered: change the spec so a file path is a valid tab cwd. Rejected because Ranger and Neo-tree's own terminal command already use the parent, and a file path is not a working directory.

### Ranger source of truth is the setup copies, then the home config

Edit `setup/fedora/ranger/` and `setup/macos/ranger/` (`rc.conf`, `commands.py`). Then copy the Fedora pair onto `~/.config/ranger/` so the viewer actually in use follows the spec. Do not copy macOS files onto this machine.

Alternative considered: edit only `~/.config/ranger`. Rejected because a later restore from `setup/` would bring back `dd` as trash, Ghostty windows, and the old tab keys.

### Shared keys are explicit Ranger maps; colliding defaults are unbound

Ranger waits when a shorter map is a prefix of a longer one. `d` cannot confirm-delete while `dd` is trash, and `y` cannot open the path menu while `yy` copies a file. Apply unbinds the colliding defaults and the keys the spec reserves:

- Unbind `dd`, `dD`, `yy`, `pp`, `L`'s old meaning, `<A-,>`, `<A-.>`, and the single keys `w`, `W`, `C`, `S`, `s`, `u`, `i`.
- Bind `d` to a confirming delete, `T` to system trash (`gio trash` on Fedora, `trash` on macOS), `c` to copy, `x` to cut (already `cut mode=add`), `p` to paste, `y` to the six-form path menu.
- Leave `L` as an alias of `oo` (`open_in_new_tab`). The spec forbids `L` as a different action; it does not forbid an alias.
- Keep `<A-t>` and `<C-A-t>` as Ranger's new-tab keys. They are not canonical shared keys.
- Keep Space as Ranger's mark toggle. Neo-tree Space stays a no-op. Marked entries are the target of Ranger `c`, `x`, `d`, and `T` when the mark set is non-empty.
- Leave `j`, `k`, `h`, `q`, `?`, and `R` on Ranger defaults (`R` reloads). Do not bind Ranger `R` to replace.

### Descend is a Ranger command, not `cd`

Bind `l` and Enter to a `descend` command. On a file it uses rifle, so the file opens and Ranger stays open. On a directory it enters it, then repeats while the directory contains exactly one child and that child is a directory. `h` stays Ranger's parent-column move, which is the miller form of ascend.

Alternative considered: bind `l` to `move right=1` and skip the single-child chain. Rejected because the spec requires the chain on both hosts, and Neo-tree already implements it in `go_deep`.

### Find and grep use the selection's directory

`fzf_files` and `fzf_rg` today search Ranger's current directory. Apply roots them at the selected directory, or at its parent when the selection is a file. A single directory result may still `cd` there; that does not change the spec.

### Preview starts off and `P` toggles it

Set `preview_files false`. `P` toggles it. Esc clears marks and the copy/cut buffer, and turns the preview off if `P` turned it on. Ranger's miller preview is a column, not Neo-tree's float; the toggle is the shared behavior.

Alternative considered: leave Ranger's preview column always on and ignore Esc. Rejected because the spec says Esc closes an open preview.

### Hidden names use `hidden_filter`, not `show_hidden!`

Replace `set show_hidden!` with `show_hidden false` and:

`hidden_filter ^\.git$|^\.DS_Store$|^thumbs\.db$`

Ranger applies `hidden_filter` only while `show_hidden` is false. A filter of those three names hides them and still lists other dotfiles and gitignored files.

### Archives stay on `zip` and `unzip`

Keep the existing sequences and commands. They do not replace a single canonical key. `u` stays unbound so `unzip` is not a second meaning of git-unstage, and the sequence can remain.

### System file manager matches Neo-tree

Ranger `O` uses the same choice as `system_file_explorer`: Nemo if it is on `PATH`, otherwise Nautilus `--select`, and `open -R` on macOS. Directories open directly. Files are selected in the parent folder.

## Risks / Trade-offs

- [Ranger config lives in two setup trees plus `~/.config/ranger`] → Implement commands once, keep OS differences in `rc.conf` only, and copy Fedora files onto the home config in the same change.
- [`d` / `y` feel delayed if any longer map remains] → Unbind `dd`, `dD`, `yy`, and `pp` in the same edit that adds the short maps, then press each key once in Ranger to confirm it does not wait.
- [Turning preview off by default hides Ranger's third column until `P`] → Accepted so preview matches Neo-tree's toggle. `P` brings the column back.
- [Unbinding `w`, `s`, `S`, `i`, and `u` drops Ranger sort, shell, and inspect on those keys] → Those keys are Neovim actions in the spec. Ranger help (`?`) must not advertise the old actions.
- [Setup copies drift from the home config again] → After editing, the Fedora home files and `setup/fedora/ranger/` should be identical.

## Migration Plan

1. Update `setup/fedora/ranger` and `setup/macos/ranger` to the shared map. Bring the Kitty `open_in_new_tab` command into both; drop the Ghostty `open_in_new_window` command.
2. Copy the Fedora `rc.conf` and `commands.py` to `~/.config/ranger/`.
3. Fix Neo-tree `oo` so a file uses its parent directory.
4. Restart Ranger and reload Neo-tree. Check `d`, `T`, `y`, `l`, `oo`, `P`, and Esc.
5. Rollback by restoring the previous `setup/*/ranger` files from git and copying the Fedora pair back to `~/.config/ranger`.
