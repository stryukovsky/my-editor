#!/usr/bin/env python3
"""Update foundryup itself."""

from common import command, main, tool


def prepare():
    return [command(tool("foundryup"), "--update")]


if __name__ == "__main__":
    raise SystemExit(main("Update foundryup itself.", prepare))
