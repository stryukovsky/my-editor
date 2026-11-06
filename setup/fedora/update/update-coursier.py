#!/usr/bin/env python3
"""Update Coursier applications."""

from common import command, main, tool


def prepare() -> list[str]:
    return [command(tool("cs"), "update")]


if __name__ == "__main__":
    raise SystemExit(main("Update Coursier applications.", prepare))
