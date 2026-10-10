from ranger.api.commands import Command
import os
import stat
import subprocess
from pathlib import Path


def _scope_directory(fm):
    """Directory to search: the selection, or its parent when the selection is a file."""
    current = fm.thisfile
    if current is not None and current.is_directory:
        return current.path
    if current is not None:
        return os.path.dirname(current.path)
    return fm.thisdir.path


def _path_in_scope(scope, name):
    if os.path.isabs(name):
        return os.path.normpath(name)
    return os.path.normpath(os.path.join(scope, name))


def _visible_children(directory):
    directory.load_content(schedule=False)
    return list(directory.files or [])


def _only_child_directory(children):
    """The single directory child, or None when descent must stop.

    Stop on an empty directory, several children, or a single file child.
    """
    if len(children) != 1:
        return None
    child = children[0]
    if not child.is_directory:
        return None
    return child


_MODE_BITS = (
    (0o400, "r"),
    (0o200, "w"),
    (0o100, "x"),
    (0o040, "r"),
    (0o020, "w"),
    (0o010, "x"),
    (0o004, "r"),
    (0o002, "w"),
    (0o001, "x"),
)
_MODE_CHARS = "rwxrwxrwx"


def _mode_string(path):
    mode = os.stat(path).st_mode
    return "".join(char if mode & bit else "-" for bit, char in _MODE_BITS)


def _parse_mode(text):
    if len(text) != 9:
        return None
    value = 0
    for index, char in enumerate(text):
        if char == "-":
            continue
        if char != _MODE_CHARS[index]:
            return None
        value |= _MODE_BITS[index][0]
    return value


def _path_forms(path):
    home = os.path.expanduser("~")
    try:
        relative_cwd = os.path.relpath(path, os.getcwd())
    except ValueError:
        relative_cwd = path
    if path == home or path.startswith(home + os.sep):
        relative_home = "~" + path[len(home) :]
    else:
        relative_home = path
    filename = os.path.basename(path.rstrip(os.sep))
    stem, extension = os.path.splitext(filename)
    if extension.startswith("."):
        extension = extension[1:]
    return [relative_cwd, path, relative_home, filename, stem, extension]


def _copy_to_clipboard(text):
    from ranger.ext.get_executables import get_executables

    managers = {
        "pbcopy": [["pbcopy"]],
        "wl-copy": [["wl-copy"]],
        "xclip": [["xclip"], ["xclip", "-selection", "clipboard"]],
        "xsel": [["xsel"], ["xsel", "-b"]],
    }
    executables = get_executables()
    commands = []
    for name in ("pbcopy", "wl-copy", "xclip", "xsel"):
        if name in executables:
            commands = managers[name]
            break
    if not commands:
        return False
    for command in commands:
        process = subprocess.Popen(command, universal_newlines=True, stdin=subprocess.PIPE)
        process.communicate(input=text)
    return True


class fzf_files(Command):
    """
    `:fzf_mark` refer from `:fzf_select`  (But Just in `Current directory and Not Recursion`)
        so just `find` is enough instead of `fdfind`)

    `:fzf_mark` can One/Multi/All Selected & Marked files of current dir that filterd by `fzf extended-search mode`
        fzf extended-search mode: https://github.com/junegunn/fzf#search-syntax
        eg:    py    'py    .py    ^he    py$    !py    !^py
    In addition:
        there is a delay in using `get_executables` (So I didn't use it)
        so there is no compatible alias.
        but find is builtin command, so you just consider your `fzf` name
    Usage
        :fzf_mark

        shortcut in fzf_mark:
            <CTRL-a>      : select all
            <CTRL-e>      : deselect all
            <TAB>         : multiple select
            <SHIFT+TAB>   : reverse multiple select
            ...           : and some remap <Alt-key> for movement
    """

    def execute(self):
        scope = _scope_directory(self.fm)
        only_directories = "-type d" if self.quantifier else r"\( -type d -o -type f -o -type l \)"
        fzf_default_command = (
            "find -L . -mindepth 1 "
            r"\( -name .git -o -name .DS_Store -o -iname thumbs.db \) -prune -o "
            f"{only_directories} -print | cut -b3-"
        )

        env = os.environ.copy()
        env["FZF_DEFAULT_COMMAND"] = fzf_default_command
        env["FZF_DEFAULT_OPTS"] = (
            "\
        --multi \
        --reverse \
        --bind ctrl-a:select-all,ctrl-e:deselect-all,alt-n:down,alt-p:up,alt-o:backward-delete-char,alt-h:beginning-of-line,alt-l:end-of-line,alt-j:backward-char,alt-k:forward-char,alt-b:backward-word,alt-f:forward-word \
        --height 95% \
        --layout reverse \
        --border \
        --preview \"cat {}  | head -n 100\""
        )

        fzf = self.fm.execute_command(
            "fzf",
            env=env,
            universal_newlines=True,
            stdout=subprocess.PIPE,
            cwd=scope,
        )
        stdout, _ = fzf.communicate()

        if fzf.returncode != 0:
            return

        filename_list = [line for line in stdout.splitlines() if line]
        abs_paths = [_path_in_scope(scope, name) for name in filename_list]
        if len(abs_paths) == 1 and os.path.isdir(abs_paths[0]):
            self.fm.cd(abs_paths[0])
        else:
            for path in abs_paths:
                self.fm.select_file(path)


class fzf_rg(Command):
    def execute(self):
        scope = _scope_directory(self.fm)
        query = self.rest(1) or ""
        command = f"""
            rg --column --line-number --no-heading --color=always --smart-case --hidden --follow -- '{query}' | \
            fzf --ansi \
                --multi \
                --reverse \
                --height=95% \
                --layout=reverse \
                --border \
                --delimiter=: \
                --preview="bat --style=numbers --color=always {{1}}:{{2}} || cat {{1}}" \
                --preview-window="right:60%:+{{2}}+3/3" \
                --bind="ctrl-a:select-all,ctrl-e:deselect-all"
        """

        fzf = self.fm.execute_command(
            command,
            universal_newlines=True,
            shell=True,
            stdout=subprocess.PIPE,
            cwd=scope,
        )
        stdout, _ = fzf.communicate()

        if fzf.returncode != 0 or not stdout.strip():
            return

        for line in stdout.strip().split("\n"):
            parts = line.split(":", 2)
            if len(parts) >= 2:
                self.fm.select_file(_path_in_scope(scope, parts[0]))


class zip_create(Command):
    """
    :zip_files_async
    Compress selected files into a ZIP archive asynchronously.
    Prompts for filename, then runs zip in background.
    """

    def execute(self):
        marked_files = self.fm.thistab.get_selection()
        if not marked_files:
            self.fm.notify("No files selected!", bad=True)
            return

        user_input = self.rest(1)
        if user_input:
            self._start_zip(user_input)
        else:
            self.fm.notify("No filename for zip archive received.", bad=True)

    def _start_zip(self, base_name):
        base_name = base_name.strip()
        if not base_name:
            return

        archive_name = base_name if base_name.endswith(".zip") else base_name + ".zip"
        cwd = self.fm.thisdir.path

        rel_paths = []
        for f in self.fm.thistab.get_selection():
            try:
                rel_paths.append(os.path.relpath(f.path, cwd))
            except ValueError:
                continue

        if not rel_paths:
            return

        cmd = ["zip", "-r", archive_name] + rel_paths
        self.fm.execute_command(cmd, cwd=cwd)
        self.fm.notify("Started zip in background")


class extract_archive(Command):
    """
    :extract_archive

    Extract common archive formats safely.
    - Creates a subdirectory named after the archive (e.g., file.zip -> file/)
    - Prevents tarbombs by never extracting directly into current directory
    - Fails if target directory already exists (no overwrite)
    """

    def execute(self):
        if not self.fm.thisfile or not self.fm.thisfile.is_file:
            return self.fm.notify("Not a file!", bad=True)

        filepath = self.fm.thisfile.path
        basename = os.path.basename(filepath)
        name, ext = os.path.splitext(basename)

        if ext in (".gz", ".bz2", ".xz"):
            name2, ext2 = os.path.splitext(name)
            if ext2 == ".tar":
                name, ext = name2, ext2 + ext

        target_dir = os.path.join(os.path.dirname(filepath), name)

        if os.path.exists(target_dir):
            return self.fm.notify(f"Directory exists: {name}", bad=True)

        cmd = None
        ext_lower = ext.lower()
        if ext_lower in (".zip",):
            cmd = ["unzip", "-q", filepath, "-d", target_dir]
        elif ext_lower in (
            ".tar",
            ".tar.gz",
            ".tgz",
            ".tar.bz2",
            ".tbz",
            ".tar.xz",
            ".txz",
        ):
            cmd = ["tar", "-xf", filepath, "-C", target_dir]
        elif ext_lower in (".7z",):
            cmd = ["7z", "x", filepath, f"-o{target_dir}"]
        elif ext_lower in (".rar",):
            cmd = ["unrar", "x", "-o+", filepath, target_dir]
        else:
            return self.fm.notify(f"Unsupported archive type: {ext}", bad=True)

        try:
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            if result.returncode == 0:
                self.fm.notify(f"Extracted to: {name}")
                self.fm.thisdir.unload()
                self.fm.thisdir.load_content()
            else:
                self.fm.notify(f"Extraction failed: {result.stderr.strip()}", bad=True)
                if os.path.exists(target_dir) and not os.listdir(target_dir):
                    os.rmdir(target_dir)
        except FileNotFoundError:
            tool = cmd[0]
            self.fm.notify(f"Tool not found: install '{tool}'", bad=True)
        except Exception as e:
            self.fm.notify(f"Error: {e}", bad=True)


class open_in_new_tab(Command):
    """
    Open the selection in a new Kitty tab in the same OS window.
    A directory is the tab cwd. A file uses its parent directory.
    """

    def execute(self):
        selected = self.fm.thistab.get_selection()
        if len(selected) != 1:
            self.fm.notify("Select exactly one item", bad=True)
            return

        f = selected[0]
        if f.is_directory:
            target_dir = f.path
        else:
            target_dir = os.path.dirname(f.path)

        socket = os.environ.get("KITTY_LISTEN_ON") or "unix:/tmp/mykitty"
        cmd = [
            "kitty",
            "@",
            "--to",
            socket,
            "launch",
            "--type=tab",
            f"--cwd={target_dir}",
            "--no-response",
        ]
        try:
            result = subprocess.run(
                cmd,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
                text=True,
            )
            if result.returncode == 0:
                self.fm.notify(f"Opened {target_dir} in new tab")
            else:
                err = (result.stderr or "").strip() or f"exit {result.returncode}"
                self.fm.notify(f"Failed to open kitty tab: {err}", bad=True)
        except FileNotFoundError:
            self.fm.notify("kitty not found", bad=True)
        except Exception as e:
            self.fm.notify(f"Failed to open kitty tab: {e}", bad=True)


class descend(Command):
    """Enter a directory, skipping a chain of single-child directories. Open a file with rifle."""

    def execute(self):
        current = self.fm.thisfile
        if current is None:
            return
        if not current.is_directory:
            self.fm.execute_file(current)
            return

        seen = set()
        self.fm.cd(current.path)
        while True:
            directory = self.fm.thisdir
            real = os.path.realpath(directory.path)
            if real in seen:
                break
            seen.add(real)
            child = _only_child_directory(_visible_children(directory))
            if child is None:
                children = directory.files or []
                if children:
                    directory.move(to=0)
                    directory.correct_pointer()
                break
            self.fm.cd(child.path)


class touch_or_mkdir(Command):
    """
    Custom :touch command:
    - If name ends with '/', create a directory.
    - Otherwise, create an empty file.
    - Automatically focuses on the new item.
    """

    def execute(self):
        if not self.arg(1):
            self.fm.notify("Usage: touch <name>", bad=True)
            return

        target = self.rest(1)
        base_dir = self.fm.thisdir.path
        full_path = os.path.join(base_dir, target)

        try:
            if target.endswith("/"):
                os.makedirs(full_path, exist_ok=True)
                self.fm.notify(f"Created directory: {target}")
            else:
                Path(full_path).parent.mkdir(parents=True, exist_ok=True)
                Path(full_path).touch(exist_ok=True)
                self.fm.notify(f"Created file: {target}")

            self.fm.thisdir.load_content(schedule=False)
            self.fm.select_file(full_path.rstrip(os.sep))
        except OSError as e:
            self.fm.notify(f"Error: {e}", bad=True)


class create_directory(Command):
    """Prompted directory name, created under the current directory and selected."""

    def execute(self):
        name = self.rest(1).strip()
        if not name:
            self.fm.notify("Usage: create_directory <name>", bad=True)
            return

        full_path = os.path.join(self.fm.thisdir.path, name).rstrip(os.sep)
        created = False
        try:
            os.makedirs(full_path)
            created = True
        except FileExistsError:
            self.fm.notify(f"Already exists: {name}", bad=True)
        except OSError as e:
            self.fm.notify(f"Error: {e}", bad=True)
            return

        self.fm.thisdir.load_content(schedule=False)
        self.fm.select_file(full_path)
        if created:
            self.fm.notify(f"Created directory: {name}")


class copy_path(Command):
    """Copy one of the six path forms to the system clipboard."""

    def execute(self):
        current = self.fm.thisfile
        if current is None:
            self.fm.notify("Select a file or directory", bad=True)
            return

        forms = _path_forms(current.path)
        prompt = "Copy path  1 cwd  2 absolute  3 home  4 name  5 stem  6 ext"
        # Enter and Esc are the first two choices and must not change the clipboard.
        cancel = "\x00"
        self.fm.ui.console.ask(
            prompt,
            lambda answer: self._apply(forms, answer),
            (cancel, cancel, "1", "2", "3", "4", "5", "6"),
        )

    def _apply(self, forms, answer):
        if answer not in "123456":
            return
        text = forms[int(answer) - 1]
        if not _copy_to_clipboard(text):
            self.fm.notify("No clipboard tool found", bad=True)
            return
        self.fm.notify(f"Copied: {text}")


class make_executable(Command):
    def execute(self):
        current = self.fm.thisfile
        if current is None or current.is_directory:
            self.fm.notify("Select a file to make it executable", bad=True)
            return

        mode = os.stat(current.path).st_mode
        os.chmod(current.path, mode | stat.S_IXUSR)
        self.fm.thisdir.load_content(schedule=False)
        self.fm.notify(f"Executable: {current.basename}")


class edit_mode(Command):
    """Prompt with the current rwx mode. Cancelling the prompt leaves it unchanged."""

    def execute(self):
        current = self.fm.thisfile
        if current is None:
            self.fm.notify("Select a file or directory", bad=True)
            return

        submitted = self.rest(1).strip()
        if not submitted:
            try:
                current_mode = _mode_string(current.path)
            except OSError as e:
                self.fm.notify(f"Cannot read mode: {e}", bad=True)
                return
            self.fm.open_console(f"edit_mode {current_mode}")
            return

        mode = _parse_mode(submitted)
        if mode is None:
            self.fm.notify("Mode must be nine characters, for example rwxr-xr-x", bad=True)
            return

        try:
            previous = os.stat(current.path).st_mode & 0o777
            if previous != mode:
                os.chmod(current.path, mode)
                message = "Mode updated: "
            else:
                message = "Mode unchanged: "
        except OSError as e:
            self.fm.notify(f"Cannot change mode: {e}", bad=True)
            return

        self.fm.thisdir.load_content(schedule=False)
        self.fm.notify(message + current.basename)


class paste_files(Command):
    def execute(self):
        if not self.fm.copy_buffer:
            self.fm.notify("Nothing to paste", bad=True)
            return

        from ranger.core.loader import CopyLoader
        from ranger.ext.safe_path import get_safe_path

        dest = self.fm.thisdir.path
        ordered = tuple(self.fm.copy_buffer)
        targets = [get_safe_path(os.path.join(dest, fobj.basename)) for fobj in ordered]
        loadable = CopyLoader(self.fm.copy_buffer, self.fm.do_cut, False, dest)
        try:
            for _ in loadable.generate():
                pass
        except OSError as e:
            self.fm.notify(f"Paste failed: {e}", bad=True)
            return

        self.fm.do_cut = False
        self.fm.thisdir.load_content(schedule=False)
        self.fm.thisdir.mark_all(False)
        for path in targets:
            for fobj in self.fm.thisdir.files or []:
                if fobj.path == path:
                    self.fm.thisdir.mark_item(fobj, True)
                    break
        if targets:
            self.fm.select_file(targets[0])


class trash_selection(Command):
    """Move the selection to the system trash and report the path.

    `trash_selection gio` uses `gio trash` (Fedora). Any other program name,
    including `trash`, is executed with the selected paths (macOS).
    """

    def execute(self):
        program = self.arg(1) or "gio"
        files = list(self.fm.thistab.get_selection())
        if not files:
            self.fm.notify("Nothing to trash", bad=True)
            return

        paths = [f.path for f in files]
        cmd = ["gio", "trash", *paths] if program == "gio" else [program, *paths]
        try:
            result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        except FileNotFoundError:
            self.fm.notify(f"Trash tool not found: {cmd[0]}", bad=True)
            return
        if result.returncode != 0:
            err = (result.stderr or result.stdout or "trash failed").strip()
            self.fm.notify(err, bad=True)
            return

        self.fm.notify("Trashed: " + ", ".join(paths))
        self.fm.thisdir.load_content(schedule=False)


class toggle_preview(Command):
    def execute(self):
        current = self.fm.thisfile
        if current is None or current.is_directory:
            return
        self.fm.settings.preview_files = not self.fm.settings.preview_files


class clear_all_selections(Command):
    def execute(self):
        self.fm.copy_buffer = set()
        self.fm.do_cut = False
        for directory in self.fm.directories.values():
            directory.mark_all(False)
        self.fm.settings.preview_files = False
        self.fm.ui.redraw_main_column()


class open_in_file_manager(Command):
    """
    Reveal the selection in the system file manager.
    Nemo if it is on PATH, otherwise Nautilus --select. macOS uses open -R for
    files and open for directories.
    """

    def execute(self):
        selected = list(self.fm.thistab.get_selection())
        if not selected and self.fm.thisfile:
            selected = [self.fm.thisfile]
        if not selected:
            self.fm.notify("Nothing selected", bad=True)
            return

        if os.uname().sysname == "Darwin":
            for fobj in selected:
                if fobj.is_directory:
                    cmd = ["open", fobj.path]
                else:
                    cmd = ["open", "-R", fobj.path]
                self._spawn(cmd)
            return

        from ranger.ext.get_executables import get_executables

        executables = get_executables()
        if "nemo" in executables:
            self._spawn(["nemo", *[fobj.path for fobj in selected]])
            return

        if "nautilus" not in executables:
            self.fm.notify("Nemo or Nautilus not found", bad=True)
            return

        directories = [fobj.path for fobj in selected if fobj.is_directory]
        files = [fobj.path for fobj in selected if not fobj.is_directory]
        if directories:
            self._spawn(["nautilus", *directories])
        if files:
            self._spawn(["nautilus", "--select", *files])

    def _spawn(self, args):
        subprocess.Popen(
            args,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            preexec_fn=os.setpgrp,
        )
