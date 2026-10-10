# Tasks

## 1. Ranger commands

- [ ] 1.1 In `setup/fedora/ranger/commands.py` and `setup/macos/ranger/commands.py`, replace `open_in_new_window` with the Kitty `open_in_new_tab` behavior from `~/.config/ranger/commands.py` (tab cwd is the directory, or the parent when the selection is a file; refuse when more than one item is marked). Verify both files define `open_in_new_tab`, and neither file still launches Ghostty or `open_in_new_window`.
- [ ] 1.2 Add a `descend` command: a file opens through rifle and Ranger stays open; a directory is entered, and entry repeats while that directory has exactly one child and that child is a directory. Verify with `python3 -m py_compile` on both `commands.py` files, and by reading the command that the single-child loop stops on an empty directory, a multi-child directory, or a single file child.
- [ ] 1.3 Add `copy_path` (the six path forms, copied to the system clipboard), `make_executable` (refuse directories), and `edit_mode` (prompt with the current mode, cancel leaves it unchanged). Extend `clear_all_selections` so Esc also clears the copy/cut buffer and turns `preview_files` off. Verify each command's class exists in both files and `python3 -m py_compile` succeeds.
- [ ] 1.4 Root `fzf_files` and `fzf_rg` at the selected directory, or at its parent when the selection is a file. Verify the search cwd is taken from that path in both files, and a cancelled fzf still changes nothing.
- [ ] 1.5 Add one `open_in_file_manager` command: Nemo if it is on `PATH`, otherwise Nautilus `--select`, and `open -R` on macOS. Directories open directly; files are selected in the parent folder. Verify `diff -q setup/fedora/ranger/commands.py setup/macos/ranger/commands.py` reports no difference, and `zip_create` / `extract_archive` are still present.

## 2. Ranger key map

- [ ] 2.1 Rewrite `setup/fedora/ranger/rc.conf` to the shared map: `l` and Enter `descend`, `a` create, `A` mkdir, `r` rename, `d` confirming delete, `T` `gio trash`, `c` copy, `x` cut, `p` paste, `y` `copy_path`, `f` / `F` the scoped searches, `oo` and `L` `open_in_new_tab`, `O` `open_in_file_manager`, `e` / `m` mode commands, `P` toggles `preview_files`, Esc `clear_all_selections`, `zip` / `unzip` unchanged, `<A-t>` and `<C-A-t>` new tab. Unbind `dd`, `dD`, `yy`, `pp`, `<A-,>`, `<A-.>`, `w`, `W`, `C`, `S`, `s`, `u`, and `i`. Set `preview_files false`, `show_hidden false`, and `hidden_filter ^\.git$|^\.DS_Store$|^thumbs\.db$`. Verify with a search that each of those bindings is present, `map dd` is absent, and `R` is not mapped to replace.
- [ ] 2.2 Write `setup/macos/ranger/rc.conf` as the same map with `T` bound to `trash` instead of `gio trash`. Verify `diff` against the Fedora `rc.conf` shows only that trash command.

## 3. Running Ranger config

- [ ] 3.1 Copy `setup/fedora/ranger/rc.conf` and `commands.py` onto `~/.config/ranger/`. Do not copy the macOS files. Verify `diff -q` is empty for both files against `setup/fedora/ranger/`.

## 4. Neo-tree alignment

- [ ] 4.1 In `lua/configs/neotree.lua`, change `open_new_window` so a file uses its parent directory as the Kitty tab cwd and a directory uses itself. Leave every filesystem key as it is, including Space as `noop`. Verify the parent-directory branch is in that command, and the filesystem mappings for `l`, `h`, `a`, `d`, `y`, `f`, `F`, `oo`, and `O` are unchanged.

## 5. Cross-viewer check

- [ ] 5.1 Walk the shared key list in `specs/file-tree-viewer/spec.md` against Neo-tree's filesystem mappings and `setup/fedora/ranger/rc.conf`. Verify each shared key is present on both sides, Ranger does not bind `s`, `u`, `i`, `S`, `w`, `W`, `C`, `<A-,>`, or `<A-.>` to another action, and Ranger `R` is left as reload.

## Workflow follow-up

- Archive the change after the tasks above are done and the map has been tried in Neo-tree and Ranger.
