#!/usr/bin/env python3
"""Update enabled external-copr repositories."""

from common import main, repository_commands


def prepare():
    return repository_commands("external-copr")


if __name__ == "__main__":
    raise SystemExit(main("Update enabled external-copr repositories.", prepare))
