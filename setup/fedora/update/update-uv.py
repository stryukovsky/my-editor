#!/usr/bin/env python3
"""Update the standalone uv installation."""

from common import command, main, tool


def prepare() -> list[str]:
    return [command("env", "UV_NO_MODIFY_PATH=1", tool("uv"), "self", "update")]


if __name__ == "__main__":
    raise SystemExit(main("Update the standalone uv installation.", prepare))
