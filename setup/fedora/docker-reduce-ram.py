#!/usr/bin/env python3
"""Limit Docker containers to a shared 512 MiB RAM and 10 GiB existing swap."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from typing import cast


CONFIG = Path("/etc/docker/daemon.json")
SLICE = Path("/etc/systemd/system/docker-limited.slice")
SLICE_CONTENT = """[Unit]
Description=Docker containers resource limits

[Slice]
MemoryMax=512M
MemorySwapMax=10G
"""


def merge_config(config: object) -> dict[str, object]:
    if not isinstance(config, dict):
        raise ValueError("Docker daemon.json must contain a JSON object")
    config = cast(dict[str, object], config)
    raw_options = config.get("exec-opts", [])
    if not isinstance(raw_options, list):
        raise ValueError("Docker exec-opts must be a list of strings")
    options: list[str] = []
    for item in cast(list[object], raw_options):
        if not isinstance(item, str):
            raise ValueError("Docker exec-opts must be a list of strings")
        options.append(item)
    if any(item.startswith("native.cgroupdriver=") and item != "native.cgroupdriver=systemd" for item in options):
        raise ValueError("Docker is configured with a non-systemd cgroup driver; migrate it first")
    if "native.cgroupdriver=systemd" not in options:
        options = [*options, "native.cgroupdriver=systemd"]
    return {**config, "exec-opts": options, "cgroup-parent": SLICE.name}


def run(*args: str) -> None:
    _ = subprocess.run(args, check=True)


def main() -> None:
    if os.geteuid() != 0:
        os.execvp("sudo", ["sudo", "--", "python3", str(Path(__file__).resolve()), *sys.argv[1:]])

    for tool in ("dockerd", "systemctl"):
        if shutil.which(tool) is None:
            raise ValueError(f"Missing required command: {tool}")
    if not Path("/sys/fs/cgroup/cgroup.controllers").is_file():
        raise ValueError("This script requires cgroup v2 (the Fedora default)")

    config = merge_config(cast(object, json.loads(CONFIG.read_text())) if CONFIG.exists() else {})
    with tempfile.TemporaryDirectory() as directory:
        candidate = Path(directory) / "daemon.json"
        _ = candidate.write_text(json.dumps(config, indent=2) + "\n")
        run("dockerd", "--validate", f"--config-file={candidate}")

        CONFIG.parent.mkdir(mode=0o755, parents=True, exist_ok=True)
        backup_dir = Path(tempfile.mkdtemp(prefix="ram-limit-backup.", dir=CONFIG.parent))
        for file in (CONFIG, SLICE):
            if file.exists():
                _ = shutil.copy2(file, backup_dir / file.name)
        print(f"Previous configuration files backed up to {backup_dir}", flush=True)

        _ = SLICE.write_text(SLICE_CONTENT)
        SLICE.chmod(0o644)
        # Restrict permissions before copying potentially sensitive daemon settings.
        CONFIG.touch(mode=0o600, exist_ok=True)
        CONFIG.chmod(0o600)
        _ = shutil.copyfile(candidate, CONFIG)

    run("systemctl", "daemon-reload")
    run("systemctl", "start", SLICE.name)
    print("Restarting Docker (may interrupt running containers)...", flush=True)
    run("systemctl", "restart", "docker.service")
    run("systemctl", "is-active", "--quiet", "docker.service")
    run("systemctl", "show", SLICE.name, "-p", "MemoryMax", "-p", "MemorySwapMax")

    print("Configured: 512 MiB RAM and up to 10 GiB swap shared by containers in docker-limited.slice.")
    print("Recreate existing containers to adopt the default parent (Compose: docker compose up -d --force-recreate).")
    print("Explicit per-container cgroup-parent settings override this default.")
    print("The swap allowance uses existing host swap, including zram; no disk swap file was created.")
    if len(Path("/proc/swaps").read_text().splitlines()) < 2:
        print("No host swap is enabled; the swap allowance cannot currently be used.", file=sys.stderr)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        sys.exit(f"Error: {error}")
