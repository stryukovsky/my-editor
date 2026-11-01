#!/usr/bin/env python3
"""Update enabled rpmfusion repositories."""

from common import main, repository_commands


def prepare():
    return repository_commands("rpmfusion")


if __name__ == "__main__":
    raise SystemExit(main("Update enabled rpmfusion repositories.", prepare))
