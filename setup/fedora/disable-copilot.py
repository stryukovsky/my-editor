#!/usr/bin/env python3
"""Consume the Lenovo Copilot shortcut in GNOME without launching anything."""
from gi.repository import Gio

schema = "org.gnome.settings-daemon.plugins.media-keys"
base = "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/"
old_path = base + "kitty-top/"
path = base + "disabled-copilot/"
settings = Gio.Settings.new(schema)
old = Gio.Settings.new_with_path(schema + ".custom-keybinding", old_path)
for key in ("name", "command", "binding"):
    old.reset(key)
shortcut = Gio.Settings.new_with_path(schema + ".custom-keybinding", path)
shortcut.set_string("name", "Copilot: disabled")
shortcut.set_string("command", "/usr/bin/true")
shortcut.set_string("binding", "<Super><Shift>F23")
paths = [p for p in settings.get_strv("custom-keybindings") if p != old_path]
if path not in paths:
    paths.append(path)
settings.set_strv("custom-keybindings", paths)

shell = Gio.Settings.new("org.gnome.shell")
extension = "kitty-top@local"
shell.set_strv("enabled-extensions", [e for e in shell.get_strv("enabled-extensions") if e != extension])
disabled = shell.get_strv("disabled-extensions")
if extension not in disabled:
    shell.set_strv("disabled-extensions", [*disabled, extension])
Gio.Settings.sync()
print("Copilot disabled in GNOME; Kitty btop shortcut and focus extension disabled.")
