"""Shared command rendering and opt-in execution. Preparation is read-only."""

import argparse
from collections.abc import Callable
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
from typing import TypedDict, cast


class Repository(TypedDict):
    id: str


def command(*args: str | Path) -> str:
    return shlex.join(str(arg) for arg in args)


def capture(*args: str) -> str:
    return subprocess.run(
        args, check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE
    ).stdout.strip()


def tool(name: str) -> str:
    roots = [
        Path.home() / ".local/bin",
        Path(os.environ.get("CARGO_HOME", Path.home() / ".cargo")) / "bin",
        Path.home() / ".foundry/bin",
        Path(os.environ.get("COURSIER_BIN_DIR", Path.home() / "Tools/coursier/bin")),
        Path.home() / "Tools",
    ]
    path = os.pathsep.join([*(str(root) for root in roots), os.environ.get("PATH", "")])
    binary = shutil.which(name, path=path)
    if not binary:
        raise RuntimeError(f"{name} is not installed")
    return binary


def nvm_source() -> list[str]:
    directory = Path(os.environ.get("NVM_DIR", Path.home() / ".nvm"))
    script = directory / "nvm.sh"
    if not script.is_file():
        raise RuntimeError(f"Missing {script}")
    return [
        f"export NVM_DIR={shlex.quote(str(directory))}",
        command("source", script, "--no-use"),
    ]


def repository_commands(group: str) -> list[str]:
    # DNF supplies the effective enabled state, including config-manager overrides.
    repos = cast(
        list[Repository],
        json.loads(capture(tool("dnf"), "repo", "list", "--enabled", "--json")),
    )
    selected: list[str] = []
    for repo in repos:
        name = repo["id"]
        if name.startswith("rpmfusion-"):
            category = "rpmfusion"
        elif name in {"fedora", "updates", "rawhide"} or name.startswith(
            ("fedora-", "updates-", "rawhide-")
        ):
            category = "fedora-core"
        else:
            category = "external-copr"
        if category == group:
            selected.append(name)
    if not selected:
        return []
    dnf = tool("dnf")
    options = ["--setopt=timeout=10", "--setopt=minrate=1000", "--setopt=retries=1"]
    repo_groups = (
        sorted(selected) if group == "rpmfusion" else [",".join(sorted(selected))]
    )
    return [
        command(
            "sudo",
            dnf,
            "upgrade",
            "-y",
            "--refresh",
            "--repo=" + repos,
            *options,
        )
        for repos in repo_groups
    ]


def main(description: str, prepare: Callable[[], list[str]]) -> int:
    parser = argparse.ArgumentParser(description=description)
    _ = parser.add_argument(
        "--run", action="store_true", help="Execute the prepared Bash commands"
    )
    args = parser.parse_args()
    run = cast(bool, args.run)
    try:
        if run and os.geteuid() == 0:
            raise RuntimeError("Run as your regular user; system updates use sudo")
        commands = prepare()
        script = (
            "\n".join(["#!/usr/bin/env bash", "set -e -o pipefail", *commands]) + "\n"
        )
        if not commands:
            script += "# Nothing to update.\n"
        print(script, end="", flush=True)
        if run:
            if commands:
                # Preserve live output and stdin for interactive prompts. Bash's
                # error trap adds context even when a command fails silently.
                error_trap = """set -E
trap 'code=$?; printf "ERROR (exit %s): %s\\n" "$code" "$BASH_COMMAND" >&2' ERR
"""
                result = subprocess.run(["bash", "-c", error_trap + script])
                if result.returncode != 0:
                    print(
                        f"{parser.prog}: ERROR (exit {result.returncode})",
                        file=sys.stderr,
                        flush=True,
                    )
                    return result.returncode
            print("OK", flush=True)
        return 0
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"{parser.prog}: ERROR: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            # Preparation commands may report useful details on either stream.
            for output in (cast(object, error.stdout), cast(object, error.stderr)):
                if isinstance(output, str) and output:
                    print(
                        output,
                        end="" if output.endswith("\n") else "\n",
                        file=sys.stderr,
                    )
        return 1
