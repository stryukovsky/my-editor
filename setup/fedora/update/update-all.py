#!/usr/bin/env python3
"""Invoke every updater, printing a separator before each one."""

import argparse
import os
from pathlib import Path
import subprocess
import sys
from typing import cast


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    _ = parser.add_argument(
        "--run",
        action="store_true",
        help="Execute updates instead of only printing commands",
    )
    args = parser.parse_args()
    run = cast(bool, args.run)
    if run and os.geteuid() == 0:
        parser.error("Run as your regular user; system updates use sudo")

    # Update system packages and managers before the tools that depend on them.
    order = [
        "fedora-core",
        "rpmfusion",
        "external-copr",
        "nvm",
        "node",
        "npm",
        "rustup",
        "rust",
        "foundryup",
        "foundry",
        "uv",
        "uv-tools",
    ]
    priority = {f"update-{name}.py": index for index, name in enumerate(order)}
    current = Path(__file__).resolve()
    scripts = sorted(
        (
            path
            for path in current.parent.glob("update-*.py")
            if path.resolve() != current
        ),
        key=lambda path: (priority.get(path.name, len(order)), path.name),
    )
    failed: list[tuple[str, int]] = []
    for script in scripts:
        print(f"\n====== RUN {script.name} ======", flush=True)
        command = [sys.executable, str(script)]
        if run:
            command.append("--run")
        result = subprocess.run(command)
        if result.returncode != 0:
            failed.append((script.name, result.returncode))

    if failed:
        print("\nFailed updaters:", file=sys.stderr)
        for name, code in failed:
            print(f"  {name} (exit {code})", file=sys.stderr)
        return 1
    if run:
        print("OK", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
