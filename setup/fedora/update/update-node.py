#!/usr/bin/env python3
"""Update the default Node major and migrate its global packages."""

import re
from common import capture, command, main, nvm_source


def prepare():
    source = nvm_source()
    previous = capture("bash", "-c", "\n".join([*source, "nvm version default"]))
    if not re.fullmatch(r"v\d+\.\d+\.\d+", previous):
        raise RuntimeError(
            "Set a default Node version with nvm alias default <version>"
        )
    major = previous.split(".")[0]
    return [
        *source,
        command("nvm", "install", major, "--reinstall-packages-from=" + previous),
        f'nvm alias default "$(nvm version {major})"',
        "nvm use default",
    ]


if __name__ == "__main__":
    raise SystemExit(
        main("Update the default Node major and migrate its global packages.", prepare)
    )
