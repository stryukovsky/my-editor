#!/usr/bin/env python3
"""Pick an installed app.

Default mode prints the command that launches it. `--path` prints the
.desktop file to edit: a file already under the user applications
directory is used as-is, and a system file is copied there first.

Every applications directory is scanned at the same time. The fzf window
opens immediately; recent apps are listed first. The last 10 picks are
stored in ~/.local/state/runapp_recents.txt as:
    id<TAB>name<TAB>command<TAB>path
"""

import asyncio
import os
import re
import shutil
import sys
from asyncio.subprocess import Process
from pathlib import Path

RECENTS = Path.home() / ".local/state/runapp_recents.txt"
MAX_RECENTS = 10
FIELD_CODE = re.compile(r"%[fFuUdDnNickvm]")

# name, command, path
Launch = tuple[str, str, str]
# id, name, command, path
Desktop = tuple[str, str, str, str]
# name, command, id, path, location — the line fzf shows and returns
Row = tuple[str, str, str, str, str]
# id -> name, command, path
Catalog = dict[str, Launch]


def user_apps_dir() -> Path:
    data_home = os.environ.get("XDG_DATA_HOME") or str(Path.home() / ".local/share")
    return Path(data_home) / "applications"


def app_dirs() -> list[Path]:
    data_dirs = os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share"
    roots = [str(user_apps_dir().parent), *[part for part in data_dirs.split(":") if part]]
    dirs: list[Path] = []
    seen: set[Path] = set()
    for root in roots:
        path = Path(root) / "applications"
        if path in seen or not path.is_dir():
            continue
        seen.add(path)
        dirs.append(path)
    return dirs


def location_label(path: str) -> str:
    if not path:
        return ""
    file = Path(path)
    if file.parent == user_apps_dir():
        return "local"
    root = file.parent.parent
    home = Path.home()
    try:
        return "~/" + root.relative_to(home).as_posix()
    except ValueError:
        return root.as_posix()


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
    return (name, cmd, path) if cmd else None


def scan_dir(directory: Path) -> list[Desktop]:
    found: list[Desktop] = []
    try:
        with os.scandir(directory) as entries:
            for entry in entries:
                if not entry.name.endswith(".desktop") or not entry.is_file():
                    continue
                parsed = parse_desktop(entry.path)
                if parsed:
                    found.append((entry.name, parsed[0], parsed[1], parsed[2]))
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
        for app_id, name, cmd, path in group:
            if app_id not in apps:
                apps[app_id] = (name, cmd, path)
    return apps


def load_recents() -> list[Desktop]:
    if not RECENTS.is_file():
        return []
    recents: list[Desktop] = []
    for line in RECENTS.read_text(encoding="utf-8", errors="replace").splitlines():
        parts = line.split("\t")
        if len(parts) < 3 or not parts[0]:
            continue
        app_id, name = parts[0], parts[1]
        if len(parts) >= 4:
            cmd, path = parts[2], parts[3]
        else:
            cmd, path = parts[2], ""
        recents.append((app_id, name, cmd, path))
        if len(recents) >= MAX_RECENTS:
            break
    return recents


def save_recents(picked: Desktop, previous: list[Desktop], apps: Catalog) -> None:
    keep: list[Desktop] = [picked]
    seen = {picked[0]}
    for app_id, name, cmd, path in previous:
        if app_id in seen:
            continue
        if app_id in apps:
            cat_name, cat_cmd, cat_path = apps[app_id]
            name = name or cat_name
            cmd = cmd or cat_cmd
            path = path or cat_path
        if not (name and cmd):
            continue
        keep.append((app_id, name, cmd, path))
        seen.add(app_id)
        if len(keep) >= MAX_RECENTS:
            break
    RECENTS.parent.mkdir(parents=True, exist_ok=True)
    text = "".join(f"{app_id}\t{name}\t{cmd}\t{path}\n" for app_id, name, cmd, path in keep)
    tmp = RECENTS.with_suffix(".txt.tmp")
    _ = tmp.write_text(text, encoding="utf-8")
    _ = tmp.replace(RECENTS)


def row_name(row: Row) -> str:
    return row[0].casefold()


def as_row(app_id: str, name: str, cmd: str, path: str) -> Row:
    return (name, cmd, app_id, path, location_label(path))


def configure_rows(recents: list[Desktop], apps: Catalog) -> list[Row]:
    rows: list[Row] = []
    shown: set[str] = set()
    for app_id, name, cmd, path in recents:
        if app_id in apps:
            name, cmd, path = apps[app_id]
        elif not (path and Path(path).is_file()):
            continue
        if not name:
            continue
        rows.append(as_row(app_id, name, cmd, path))
        shown.add(app_id)
    rest = sorted(
        (
            as_row(app_id, name, cmd, path)
            for app_id, (name, cmd, path) in apps.items()
            if app_id not in shown
        ),
        key=row_name,
    )
    return rows + rest


def editable_desktop(path: str, tool: str) -> Path | None:
    """Return the user-writable .desktop file, copying a system file first."""
    if not path:
        return None
    source = Path(path)
    if not source.is_file():
        return None
    user_dir = user_apps_dir()
    if source.parent == user_dir:
        return source
    user_dir.mkdir(parents=True, exist_ok=True)
    dest = user_dir / source.name
    if dest.exists():
        print(f"{tool}: editing {dest}", file=sys.stderr)
        return dest
    shutil.copy2(source, dest)
    print(f"{tool}: copied to {dest}", file=sys.stderr)
    return dest


async def write_rows(proc: Process, rows: list[Row]) -> None:
    if not rows or proc.stdin is None:
        return
    data = "".join(
        f"{name}\t{cmd}\t{app_id}\t{path}\t{location}\n"
        for name, cmd, app_id, path, location in rows
    ).encode()
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
    parts = out.decode(errors="replace").splitlines()[0].split("\t")
    if len(parts) < 3:
        return None
    name, cmd, app_id = parts[0], parts[1], parts[2]
    path = parts[3] if len(parts) > 3 else ""
    return app_id, name, cmd, path


async def finish_scan(scan_task: asyncio.Task[Catalog], *, cancel: bool) -> Catalog:
    if cancel and not scan_task.done():
        _ = scan_task.cancel()
    try:
        return await scan_task
    except asyncio.CancelledError:
        return {}


async def run(path_mode: bool) -> int:
    tool = "configureapp" if path_mode else "runapp"
    dirs = app_dirs()
    recents = load_recents()
    scan_task = asyncio.create_task(collect(dirs))
    header = (
        "recent first - Enter opens the .desktop file in $EDITOR"
        if path_mode
        else "recent first - Enter runs the command here"
    )
    nth = "1,5" if path_mode else "1,2"
    try:
        proc = await asyncio.create_subprocess_exec(
            "fzf",
            "--delimiter=\t",
            f"--with-nth={nth}",
            f"--header={header}",
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
        )
    except FileNotFoundError:
        _ = await finish_scan(scan_task, cancel=True)
        print(f"{tool}: fzf not found", file=sys.stderr)
        return 1

    shown: set[str] = set()
    apps: Catalog = {}
    try:
        if path_mode:
            apps = await scan_task
            await write_rows(proc, configure_rows(recents, apps))
        else:
            ready = [as_row(app_id, name, cmd, path) for app_id, name, cmd, path in recents if name and cmd]
            await write_rows(proc, ready)
            shown.update(app_id for _, _, app_id, _, _ in ready)

            apps = await scan_task
            deferred: list[Row] = []
            for app_id, _, _, _ in recents:
                if app_id in shown or app_id not in apps:
                    continue
                name, cmd, path = apps[app_id]
                deferred.append(as_row(app_id, name, cmd, path))
                shown.add(app_id)
            rest = sorted(
                (
                    as_row(app_id, name, cmd, path)
                    for app_id, (name, cmd, path) in apps.items()
                    if app_id not in shown
                ),
                key=row_name,
            )
            await write_rows(proc, deferred + rest)
    except OSError:
        apps = await finish_scan(scan_task, cancel=False)
    choice = await read_choice(proc)
    if not choice:
        return 1
    app_id, name, cmd, path = choice
    if app_id in apps:
        cat_name, cat_cmd, cat_path = apps[app_id]
        name = name or cat_name
        cmd = cmd or cat_cmd
        path = path or cat_path
    if path_mode:
        edited = editable_desktop(path, tool)
        if edited is None:
            print(f"{tool}: no desktop file for {name or app_id}", file=sys.stderr)
            return 1
        path = str(edited)
        output = path
    else:
        output = cmd
    try:
        save_recents((app_id, name, cmd, path), recents, apps)
    except OSError as exc:
        print(f"{tool}: could not save recents: {exc}", file=sys.stderr)
    print(output)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(asyncio.run(run("--path" in sys.argv[1:])))
    except (KeyboardInterrupt, BrokenPipeError):
        raise SystemExit(1)
