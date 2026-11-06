#!/usr/bin/env python3
"""Update SDKMAN, metadata and installed SDKs (interactive)."""

import os
from pathlib import Path
import shlex
from common import command, main


def prepare() -> list[str]:
    directory = Path(os.environ.get("SDKMAN_DIR", Path.home() / ".sdkman"))
    script = directory / "bin/sdkman-init.sh"
    if not script.is_file():
        raise RuntimeError(f"Missing {script}")
    return [
        f"export SDKMAN_DIR={shlex.quote(str(directory))}",
        command("source", script),
        "sdk selfupdate",
        "sdk update",
        "sdk upgrade",
    ]


if __name__ == "__main__":
    raise SystemExit(
        main("Update SDKMAN, metadata and installed SDKs (interactive).", prepare)
    )
