# Adapted from wezterm: https://github.com/wez/wezterm/blob/main/assets/wezterm-nautilus.py
# original copyright notice:
#
# Copyright (C) 2022 Sebastian Wiesner <sebastian@swsnr.de>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

from pathlib import Path
import gettext
import builtins
import json
import os
import subprocess
import threading
import logging
import shutil
from gi.repository import Nautilus, GObject

DOMAIN = "kitty"
locale_dir = Path(__file__).absolute().parents[2] / "locale"
_ = gettext.translation(DOMAIN, locale_dir, fallback=True).gettext

def open_in_kitty_activated(_menu, paths):
    def launch_tabs():
        log_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
        log_dir.mkdir(parents=True, exist_ok=True)
        logger = logging.getLogger("kitty-nautilus")
        if not logger.handlers:
            handler = logging.FileHandler(log_dir / "kitty-nautilus.log")
            handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
            logger.addHandler(handler)
            logger.setLevel(logging.INFO)
        kitten = shutil.which("kitten") or "/usr/bin/kitten"
        logger.info("Opening tabs for %r using %s", paths, kitten)

        def run(arguments):
            command = [kitten, "@", *arguments]
            result = subprocess.run(command, capture_output=True, text=True, timeout=10)
            if result.returncode:
                raise RuntimeError(f"{command!r}: {result.stderr.strip() or result.stdout.strip()}")
            return result

        try:
            _launch_tabs(run, logger)
        except Exception:
            logger.exception("Open in Kitty failed")

    def _launch_tabs(run, logger):
        # Kitty appends its PID to the configured /tmp/mykitty socket name.
        sockets = sorted(Path("/tmp").glob("mykitty-*"), key=lambda p: int(p.name.rsplit("-", 1)[-1]) if p.name.rsplit("-", 1)[-1].isdigit() else 0, reverse=True)
        addresses = list(dict.fromkeys(filter(None, [os.environ.get("KITTY_LISTEN_ON")] +
                                             [f"unix:{p}" for p in sockets if p.is_socket()])))
        instances = []
        for address in addresses:
            try:
                result = run(["--to", address, "ls"])
                windows = json.loads(result.stdout)
                instances.append((address, any(w.get("is_focused") for w in windows)))
            except (OSError, subprocess.SubprocessError, ValueError, RuntimeError) as error:
                logger.warning("Cannot query %s: %s", address, error)
                continue
        if not instances:
            logger.error("No running Kitty instance with remote control available; tried %r", addresses)
            return
        address = next((address for address, focused in instances if focused), instances[0][0])
        try:
            for path in paths:
                result = run(["--to", address, "launch", "--type=tab", "--cwd", path])
                window_id = result.stdout.strip()
                logger.info("Opened window %s as a tab via %s", window_id, address)
                run(["--to", address, "focus-window", "--match", f"id:{window_id}"])
        except (OSError, subprocess.SubprocessError, RuntimeError):
            logger.exception("Tab launch or focus failed via %s", address)

    threading.Thread(target=launch_tabs, daemon=True).start()


def get_paths_to_open(files):
    paths = []
    for file in files:
        location = file.get_location() if file.is_directory() else file.get_parent_location()
        path = location.get_path()
        if path and path not in paths:
            paths.append(path)
    if 10 < len(paths):
        # Let's not open anything if the user selected a lot of directories,
        # to avoid accidentally spamming their desktop with dozends of
        # new windows or tabs.  Ten is a totally arbitrary limit :)
        return []
    else:
        return paths


def get_items_for_files(name, files):
    paths = get_paths_to_open(files)
    if paths:
        item = Nautilus.MenuItem(name=name, label=_('Open in Kitty'),
            icon='kitty')
        item.connect('activate', open_in_kitty_activated, paths)
        return [item]
    else:
        return []


class KittyMenuProvider(GObject.GObject, Nautilus.MenuProvider):
    def __init__(self):
        super().__init__()
        # nautilus-python can register this module from both user and system
        # extension directories. Only one provider should contribute menu items.
        if not hasattr(builtins, "_kitty_nautilus_provider"):
            builtins._kitty_nautilus_provider = self

    def get_file_items(self, files):
        if builtins._kitty_nautilus_provider is not self:
            return []
        return get_items_for_files('KittyNautilus::open_in_kitty', files)

    def get_background_items(self, file):
        if builtins._kitty_nautilus_provider is not self:
            return []
        return get_items_for_files('KittyNautilus::open_folder_in_kitty', [file])
