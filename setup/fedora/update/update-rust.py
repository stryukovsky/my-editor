#!/usr/bin/env python3
"""Update installed Rust toolchains and components."""

from common import command, main, tool


def prepare():
    return [command(tool("rustup"), "update")]


if __name__ == "__main__":
    raise SystemExit(main("Update installed Rust toolchains and components.", prepare))
