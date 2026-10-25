# Open in Kitty

User Nautilus extension for opening selected files' parent directories or the
current directory in a new tab of a running Kitty instance. Requires Kitty,
`kitten`, and nautilus-python. Uses the existing Kitty configuration's
`allow_remote_control socket-only` and `listen_on unix:/tmp/mykitty` settings.
Prefers the focused instance; otherwise uses the instance with the highest PID.
If no instance is running, no window is opened.

Run as your desktop user:

```sh
bash ~/.config/nvim/setup/fedora/gnome.sh
```

The installer symlinks `ghostty.py` in the user extension directory to this
folder's `kitty.py`. The filename intentionally overrides the system Ghostty
extension, replacing its menu action with **Open in Kitty**.
An instance guard prevents duplicate menu items when Nautilus registers the
module from both extension directories.

Run `nautilus -q`, then reopen Files to load the extension.

The action records commands' errors and successful tab launches in
`~/.cache/kitty-nautilus.log` (or `$XDG_CACHE_HOME/kitty-nautilus.log`).
