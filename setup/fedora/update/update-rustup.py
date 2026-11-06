#!/usr/bin/env python3
"""Update rustup itself."""

from common import command, main, tool


def prepare() -> list[str]:
    return [command(tool("rustup"), "self", "update")]


if __name__ == "__main__":
    raise SystemExit(main("Update rustup itself.", prepare))
