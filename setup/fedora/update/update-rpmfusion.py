#!/usr/bin/env python3
"""Update enabled rpmfusion repositories."""

from pathlib import Path
from common import command, main, repository_commands


def prepare() -> list[str]:
    return [
        command(
            "sudo",
            "install",
            "-Dm644",
            Path(__file__).resolve().parent.parent / "rpmfusion-yandex.repo",
            "/etc/dnf/repos.override.d/99-rpmfusion-yandex.repo",
        ),
        *repository_commands("rpmfusion"),
    ]


if __name__ == "__main__":
    raise SystemExit(main("Update enabled rpmfusion repositories.", prepare))
