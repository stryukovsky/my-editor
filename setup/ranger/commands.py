from ranger.api.commands import Command
import os
import subprocess
import urllib.parse
from pathlib import Path


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
        # from pathlib import Path  # Py3.4+
        import os
        import subprocess

        fzf_name = "fzf"

        hidden = "-false" if self.fm.settings.show_hidden else r"-path '*/\.*' -prune"
        exclude = r"\( -name '\.git' -o -iname '\.*py[co]' -o -fstype 'dev' -o -fstype 'proc' \) -prune"
        only_directories = "-type d" if self.quantifier else ""
        fzf_default_command = "find -L . -mindepth 1 -type d -prune {} -o {} -o {} -print | cut -b3-".format(
            hidden, exclude, only_directories
        )

        env = os.environ.copy()
        env["FZF_DEFAULT_COMMAND"] = fzf_default_command

        # you can remap and config your fzf (and your can still use ctrl+n / ctrl+p ...) + preview
        env["FZF_DEFAULT_OPTS"] = (
            '\
        --multi \
        --reverse \
        --bind ctrl-a:select-all,ctrl-e:deselect-all,alt-n:down,alt-p:up,alt-o:backward-delete-char,alt-h:beginning-of-line,alt-l:end-of-line,alt-j:backward-char,alt-k:forward-char,alt-b:backward-word,alt-f:forward-word \
        --height 95% \
        --layout reverse \
        --border \
        --preview "cat {}  | head -n 100"'
        )
        # if use bat instead of cat, you need install it
        # --preview "bat --style=numbers --color=always --line-range :500 {}"'

        fzf = self.fm.execute_command(
            fzf_name, env=env, universal_newlines=True, stdout=subprocess.PIPE
        )
        stdout, _ = fzf.communicate()

        if fzf.returncode == 0:
            filename_list = stdout.strip().split()
            abs_paths = [os.path.abspath(f) for f in filename_list]
            if len(abs_paths) == 1 and os.path.isdir(abs_paths[0]):
                self.fm.cd(abs_paths[0])
            else:
                for filename in filename_list:
                    # Python3.4+
                    # self.fm.select_file( str(Path(filename).resolve()) )
                    self.fm.select_file(os.path.abspath(filename))
                    # self.fm.mark_files(all=False,toggle=True)


class fzf_rg(Command):
    def execute(self):
        query = self.rest(1) or ""

        # Use shell pipeline: rg → fzf
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
            command, universal_newlines=True, shell=True, stdout=subprocess.PIPE
        )
        stdout, _ = fzf.communicate()

        if fzf.returncode == 0 and stdout.strip():
            for line in stdout.strip().split("\n"):
                parts = line.split(":", 2)
                if len(parts) >= 2:
                    filepath = parts[0]
                    self.fm.select_file(os.path.abspath(filepath))


import threading


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
        # You can then use the input in your command
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
        self.fm.notify(f"Started zip in background")


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

        # Handle double extensions like .tar.gz
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
            result = subprocess.run(
                cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
            )
            if result.returncode == 0:
                self.fm.notify(f"Extracted to: {name}")
                self.fm.thisdir.unload()
                self.fm.thisdir.load_content()
            else:
                self.fm.notify(f"Extraction failed: {result.stderr.strip()}", bad=True)
                # Clean up empty directory on failure
                if os.path.exists(target_dir) and not os.listdir(target_dir):
                    os.rmdir(target_dir)
        except FileNotFoundError:
            tool = cmd[0]
            self.fm.notify(f"Tool not found: install '{tool}'", bad=True)
        except Exception as e:
            self.fm.notify(f"Error: {e}", bad=True)


class open_in_tmux_window(Command):
    def execute(self):
        selected = self.fm.thistab.get_selection()
        if len(selected) != 1:
            self.fm.notify("Select exactly one item", bad=True)
            return

        if not os.environ.get("TMUX"):
            self.fm.notify("Not running inside tmux", bad=True)
            return

        f = selected[0]
        if f.is_directory:
            target_dir = f.path
        else:
            target_dir = os.path.dirname(f.path)

        try:
            subprocess.Popen(["tmux", "new-window", "-c", target_dir])
            self.fm.notify(f"Opened {target_dir} in new tmux window")
        except Exception as e:
            self.fm.notify(f"Failed to open tmux window: {e}", bad=True)


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

        target = self.rest(1)  # Get full argument
        base_dir = self.fm.thisdir.path
        full_path = os.path.join(base_dir, target)

        try:
            if target.endswith("/"):
                # Create directory
                os.makedirs(full_path, exist_ok=True)
                self.fm.notify(f"Created directory: {target}")
            else:
                # Create file and any missing parent directories
                Path(full_path).parent.mkdir(parents=True, exist_ok=True)
                Path(full_path).touch(exist_ok=True)
                self.fm.notify(f"Created file: {target}")

            # Refresh the directory content and select the new file
            self.fm.thisdir.load_content()
            self.fm.select_file(full_path)

        except OSError as e:
            self.fm.notify(f"Error: {e}", bad=True)


class clear_all_selections(Command):
    def execute(self):
        self.fm.copy_buffer = set()
        self.fm.thisdir.mark_all(False)
        self.fm.ui.redraw_main_column()


class open_in_nautilus(Command):
    """
    :open_in_nautilus

    Open selected items in GNOME Files (Nautilus):
      - Directories are opened directly.
      - Files are selected in their parent folder.
    """

    def execute(self):
        from ranger.ext.get_executables import get_executables

        if "nautilus" not in get_executables():
            self.fm.notify("Nautilus not found!", bad=True)
            return

        selected = [f.path for f in self.fm.thistab.get_selection()]
        if not selected:
            selected = [self.fm.thisfile.path]

        dirs = []
        files = []

        for path in selected:
            p = Path(path)
            if p.is_dir():
                dirs.append(str(p))
            else:
                # Only add file if it exists (avoid broken selections)
                if p.exists():
                    files.append(str(p))

        args = ["nautilus"]

        # Add directories to open directly
        if dirs:
            args.extend(dirs)

        # Add files to select
        if files:
            args.append("--select")
            args.extend(files)

        if len(args) > 1:  # Avoid running "nautilus" with no args unless intended
            subprocess.Popen(
                args,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                preexec_fn=os.setpgrp,
            )
