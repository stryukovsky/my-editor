#!/usr/bin/env python3
"""Update user Flatpak apps and runtimes."""

from common import command, main, tool


def prepare():
    return [command(tool("flatpak"), "update", "--user")]


if __name__ == "__main__":
    raise SystemExit(main("Update user Flatpak apps and runtimes.", prepare))
