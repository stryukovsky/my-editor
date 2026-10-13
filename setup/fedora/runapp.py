#!/usr/bin/env python3
"""Pick an installed app and print the command that launches it.

Every applications directory is scanned at the same time. The fzf window
opens immediately; recent apps are listed first. The last 10 picks are
stored in ~/.local/state/runapp_recents.txt as:
    id<TAB>name<TAB>command
"""

import asyncio
import os
import re
import sys
from asyncio.subprocess import Process
from pathlib import Path

RECENTS = Path.home() / ".local/state/runapp_recents.txt"
MAX_RECENTS = 10
FIELD_CODE = re.compile(r"%[fFuUdDnNickvm]")

# name, command
Launch = tuple[str, str]
# id, name, command
Desktop = tuple[str, str, str]
# name, command, id — the line fzf shows and returns
Row = tuple[str, str, str]
# id -> name, command
Catalog = dict[str, Launch]


def app_dirs() -> list[Path]:
    home = Path.home()
    data_home = os.environ.get("XDG_DATA_HOME") or str(home / ".local/share")
    data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    roots = [data_home, *[part for part in data_dirs.split(":") if part]]
    dirs: list[Path] = []
    for root in roots:
        path = Path(root) / "applications"
        if path.is_dir():
            dirs.append(path)
    return dirs


def clean_exec(raw: str) -> str:
    cmd = raw.replace("%%", "\0")
    cmd = FIELD_CODE.sub("", cmd).replace("\0", "%")
    cmd = cmd.replace("@@u", "").replace("@@", "").replace("--file-forwarding", "")
    return " ".join(cmd.replace("\t", " ").split())


def parse_desktop(path: str) -> Launch | None:
    name: str | None = None
    exec_: str | None = None
    type_: str | None = None
    hide = False
    in_entry = False
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for raw in fh:
                line = raw.strip()
                if not line or line.startswith("#"):
                    continue
                if line.startswith("["):
                    if in_entry:
                        break
                    in_entry = line == "[Desktop Entry]"
                    continue
                if not in_entry or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                value = value.strip()
                if key == "Name" and name is None:
                    name = " ".join(value.replace("\t", " ").split())
                elif key == "Exec" and exec_ is None:
                    exec_ = value
                elif key == "Type" and type_ is None:
                    type_ = value
                elif key in ("NoDisplay", "Hidden") and value == "true":
                    hide = True
    except OSError:
        return None
    if hide or type_ != "Application" or not name or not exec_:
        return None
    cmd = clean_exec(exec_)
    return (name, cmd) if cmd else None


def scan_dir(directory: Path) -> list[Desktop]:
    found: list[Desktop] = []
    try:
        with os.scandir(directory) as entries:
            for entry in entries:
                if not entry.name.endswith(".desktop") or not entry.is_file():
                    continue
                parsed = parse_desktop(entry.path)
                if parsed:
                    found.append((entry.name, parsed[0], parsed[1]))
    except OSError:
        return []
    return found


async def collect(dirs: list[Path]) -> Catalog:
    """Scan every applications folder concurrently. Earlier folders win."""
    groups: list[list[Desktop]] = await asyncio.gather(
        *(asyncio.to_thread(scan_dir, directory) for directory in dirs)
    )
    apps: Catalog = {}
    for group in groups:
        for app_id, name, cmd in group:
            if app_id not in apps:
                apps[app_id] = (name, cmd)
    return apps


def load_recents() -> list[Desktop]:
    if not RECENTS.is_file():
        return []
    recents: list[Desktop] = []
    for line in RECENTS.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line:
            continue
        parts = line.split("\t")
        app_id = parts[0]
        name = parts[1] if len(parts) >= 3 else ""
        cmd = "\t".join(parts[2:]) if len(parts) >= 3 else ""
        recents.append((app_id, name, cmd))
        if len(recents) >= MAX_RECENTS:
            break
    return recents


def save_recents(picked: Desktop, previous: list[Desktop], apps: Catalog) -> None:
    keep: list[Desktop] = [picked]
    seen = {picked[0]}
    for app_id, name, cmd in previous:
        if app_id in seen:
            continue
        if not (name and cmd) and app_id in apps:
            name, cmd = apps[app_id]
        if not (name and cmd):
            continue
        keep.append((app_id, name, cmd))
        seen.add(app_id)
        if len(keep) >= MAX_RECENTS:
            break
    RECENTS.parent.mkdir(parents=True, exist_ok=True)
    text = "".join(f"{app_id}\t{name}\t{cmd}\n" for app_id, name, cmd in keep)
    tmp = RECENTS.with_suffix(".txt.tmp")
    _ = tmp.write_text(text, encoding="utf-8")
    _ = tmp.replace(RECENTS)


def row_name(row: Row) -> str:
    return row[0].casefold()


async def write_rows(proc: Process, rows: list[Row]) -> None:
    if not rows or proc.stdin is None:
        return
    data = "".join(f"{name}\t{cmd}\t{app_id}\n" for name, cmd, app_id in rows).encode()
    proc.stdin.write(data)
    await proc.stdin.drain()


async def read_choice(proc: Process) -> Desktop | None:
    if proc.stdin is not None and not proc.stdin.is_closing():
        proc.stdin.close()
        try:
            await proc.stdin.wait_closed()
        except OSError:
            pass
    out = await proc.stdout.read() if proc.stdout is not None else b""
    _ = await proc.wait()
    if not out.strip():
        return None
    parts = out.decode(errors="replace").splitlines()[0].split("\t", 2)
    if len(parts) != 3:
        return None
    name, cmd, app_id = parts
    return app_id, name, cmd


async def finish_scan(scan_task: asyncio.Task[Catalog]) -> Catalog:
    if not scan_task.done():
        _ = scan_task.cancel()
    try:
        return await scan_task
    except asyncio.CancelledError:
        return {}


async def run() -> int:
    dirs = app_dirs()
    recents = load_recents()
    scan_task = asyncio.create_task(collect(dirs))
    try:
        proc = await asyncio.create_subprocess_exec(
            "fzf",
            "--delimiter=\t",
            "--with-nth=1,2",
            "--header=recent first - Enter runs the command here",
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
        )
    except FileNotFoundError:
        _ = await finish_scan(scan_task)
        print("runapp: fzf not found", file=sys.stderr)
        return 1

    shown: set[str] = set()
    apps: Catalog = {}
    try:
        ready: list[Row] = [(name, cmd, app_id) for app_id, name, cmd in recents if name and cmd]
        await write_rows(proc, ready)
        shown.update(app_id for _, _, app_id in ready)

        apps = await scan_task
        deferred: list[Row] = []
        for app_id, _, _ in recents:
            if app_id in shown or app_id not in apps:
                continue
            name, cmd = apps[app_id]
            deferred.append((name, cmd, app_id))
            shown.add(app_id)
        rest = sorted(
            ((name, cmd, app_id) for app_id, (name, cmd) in apps.items() if app_id not in shown),
            key=row_name,
        )
        await write_rows(proc, deferred + rest)
    except OSError:
        apps = await finish_scan(scan_task)
    choice = await read_choice(proc)
    if not choice:
        return 1
    try:
        save_recents(choice, recents, apps)
    except OSError as exc:
        print(f"runapp: could not save recents: {exc}", file=sys.stderr)
    print(choice[2])
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(asyncio.run(run()))
    except (KeyboardInterrupt, BrokenPipeError):
        raise SystemExit(1)
