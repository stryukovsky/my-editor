#!/usr/bin/env python3
"""Update the stable Foundry toolchain."""

from common import command, main, tool


def prepare():
    return [command(tool("foundryup"))]


if __name__ == "__main__":
    raise SystemExit(main("Update the stable Foundry toolchain.", prepare))
