#!/usr/bin/env python3
"""Update Oh My Zsh."""

import os
from pathlib import Path
from common import command, main, tool


def prepare():
    directory = Path(os.environ.get("ZSH", Path.home() / ".oh-my-zsh"))
    script = directory / "tools/upgrade.sh"
    if not script.is_file():
        raise RuntimeError(f"Missing {script}")
    return [command("env", f"ZSH={directory}", tool("zsh"), script)]


if __name__ == "__main__":
    raise SystemExit(main("Update Oh My Zsh.", prepare))
