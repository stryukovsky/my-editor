#!/usr/bin/env python3
"""Update system Flatpak apps and runtimes."""

from common import command, main, tool


def prepare() -> list[str]:
    return [command(tool("flatpak"), "update", "--system")]


if __name__ == "__main__":
    raise SystemExit(main("Update system Flatpak apps and runtimes.", prepare))
