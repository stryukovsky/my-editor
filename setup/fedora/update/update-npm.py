#!/usr/bin/env python3
"""Update npm and global packages for the default Node version."""

from common import main, nvm_source


def prepare():
    return [
        *nvm_source(),
        "nvm use default",
        "nvm install-latest-npm",
        "npm update --global",
    ]


if __name__ == "__main__":
    raise SystemExit(
        main("Update npm and global packages for the default Node version.", prepare)
    )
