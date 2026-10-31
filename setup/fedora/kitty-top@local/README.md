# Copilot → Kitty btop

Run `python3 ~/.config/nvim/bin/kitty-top --install-shortcut` as the desktop user,
then log out and back in once to load this local GNOME 50 extension.
`setup/fedora/gnome.sh` also runs the installer. It preserves existing shortcuts
and enabled extensions. The Copilot shortcut is Super+Shift+F23.

The Python launcher searches every Kitty socket configured as `/tmp/mykitty-*`,
then every OS window, tab and pane for a foreground `btop` process. It selects an
existing btop, opens a new btop tab, or launches Kitty with btop when no instance
is running. A runtime lock prevents duplicate launches from repeated keypresses.

On GNOME Wayland, remote control selects a tab but cannot reliably raise its OS
window. This extension exports only `org.gnome.Shell.Extensions.KittyTop.Focus`
at `/org/gnome/Shell/Extensions/KittyTop`. It activates a Kitty window matching
the selected tab's title and the socket owner's process ID, including windows
on another workspace. It does not enable Shell Eval or change focus policies.

Requires the existing Kitty settings `allow_remote_control socket-only` and
`listen_on unix:/tmp/mykitty`, Python 3 and GNOME's PyGObject package. Existing
Kitty processes must have remote control enabled. Detection covers local btop
processes exposed by Kitty, not btop nested inside tmux or a remote SSH session.
