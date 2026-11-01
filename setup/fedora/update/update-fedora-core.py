#!/usr/bin/env python3
"""Update enabled fedora-core repositories."""

from common import main, repository_commands


def prepare():
    return repository_commands("fedora-core")


if __name__ == "__main__":
    raise SystemExit(main("Update enabled fedora-core repositories.", prepare))
