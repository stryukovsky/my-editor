#!/usr/bin/env python3
"""Rebuild Go applications using their embedded package paths at latest."""

import os
from pathlib import Path
from common import capture, command, main, tool


def prepare():
    go = tool("go")
    bin_dir = Path(
        os.environ.get("GOBIN")
        or (Path(capture(go, "env", "GOPATH").split(os.pathsep)[0]) / "bin")
    )
    commands = []
    if not bin_dir.is_dir():
        return commands
    for binary in sorted(bin_dir.iterdir()):
        if not binary.is_file() or not os.access(binary, os.X_OK):
            continue
        metadata = capture(go, "version", "-m", str(binary))
        package = next(
            (
                parts[1]
                for line in metadata.splitlines()
                if len(parts := line.split()) == 2 and parts[0] == "path"
            ),
            None,
        )
        if package and package != "command-line-arguments":
            commands.append(
                command("env", f"GOBIN={bin_dir}", go, "install", package + "@latest")
            )
    return commands


if __name__ == "__main__":
    raise SystemExit(
        main(
            "Rebuild Go applications using their embedded package paths at latest.",
            prepare,
        )
    )
