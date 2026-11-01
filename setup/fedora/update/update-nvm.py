#!/usr/bin/env python3
"""Update the existing nvm Git installation to the latest release tag."""

import os
from pathlib import Path
import re
from common import capture, command, main, nvm_source, tool


def prepare():
    nvm_source()  # Require an existing installation.
    directory = Path(os.environ.get("NVM_DIR", Path.home() / ".nvm"))
    if not (directory / ".git").exists():
        raise RuntimeError("This updater requires a Git installation of nvm")
    git = tool("git")
    remote = capture(
        git, "-C", str(directory), "ls-remote", "--tags", "--refs", "origin"
    )
    tags = [
        line.split("refs/tags/", 1)[1]
        for line in remote.splitlines()
        if "refs/tags/" in line
    ]
    versions = [tag for tag in tags if re.fullmatch(r"v\d+\.\d+\.\d+", tag)]
    if not versions:
        raise RuntimeError("No nvm release tags found on origin")
    tag = max(versions, key=lambda value: tuple(map(int, value[1:].split("."))))
    return [
        command(git, "-C", directory, "fetch", "origin", "tag", tag),
        command(git, "-C", directory, "checkout", "--detach", tag),
    ]


if __name__ == "__main__":
    raise SystemExit(
        main(
            "Update the existing nvm Git installation to the latest release tag.",
            prepare,
        )
    )
