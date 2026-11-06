#!/usr/bin/env python3
"""Update uv-installed tools."""

from common import command, main, tool


def prepare() -> list[str]:
    return [command(tool("uv"), "tool", "upgrade", "--all")]


if __name__ == "__main__":
    raise SystemExit(main("Update uv-installed tools.", prepare))
