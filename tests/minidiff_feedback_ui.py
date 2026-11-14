"""Run: uv run --with pynvim python tests/minidiff_feedback_ui.py

Uses the configured Neovim with an attached UI and a disposable Git index.
"""
from pathlib import Path
import os
import subprocess
import tempfile
import time

import pynvim


def wait(predicate, label, timeout=8):
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if predicate():
            return
        time.sleep(0.02)
    raise AssertionError(label)


with tempfile.TemporaryDirectory(prefix="minidiff-ui-", dir="/tmp/opencode") as directory:
    root = Path(directory)
    subprocess.run(["git", "init", "-q", directory], check=True)
    tracked = root / "tracked.txt"
    clean = root / "clean.txt"
    missing = root / "untracked.txt"
    tracked.write_text("old\ncontext\n")
    clean.write_text("clean\n")
    missing.write_text("untracked\n")
    subprocess.run(["git", "-C", directory, "add", "tracked.txt", "clean.txt"], check=True)
    tracked.write_text("edited\ncontext\n")
    os.environ["NVIM_LOG_FILE"] = str(root / "nvim.log")
    nvim = pynvim.attach("child", argv=["nvim", "--embed", "-i", "NONE", "-n"])
    nvim.ui_attach(120, 40, rgb=True)
    try:
        nvim.exec_lua("""
            local diff = require 'mini.diff'
            for i = 1, 10 do
                local _, value = debug.getupvalue(diff.enable, i)
                if type(value) == 'table' and value.cache then
                    local read = value.git_read_reference
                    value.git_read_reference = function(args, cwd, callback)
                        read(args, cwd, function(...)
                            local result = { ... }
                            vim.defer_fn(function() callback(unpack(result)) end, 1200)
                        end)
                    end
                    break
                end
            end
        """)
        nvim.command("edit " + str(tracked))
        buf = nvim.current.buffer.number
        state = lambda: nvim.exec_lua("return require('mini.diff').get_buf_state(...)", buf)
        wait(lambda: state() and state()["status"] == "loading", "initial loading")
        assert nvim.exec_lua("return require('moonshine.diff').lualine_hunks()") == "diff: loading…"
        nvim.exec_lua("require('moonshine.diff').preview()")

        def loading_windows():
            return nvim.exec_lua(r"""
                local count = 0
                for _, win in ipairs(vim.api.nvim_list_wins()) do
                    local buf = vim.api.nvim_win_get_buf(win)
                    if vim.bo[buf].filetype == 'notify' then
                        local text = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
                        if text:find('Diff is loading', 1, true) then count = count + 1 end
                    end
                end
                return count
            """)

        wait(lambda: loading_windows() == 1, "loading notification visible")
        nvim.exec_lua("require('moonshine.diff').preview(); require('moonshine.diff').preview()")
        time.sleep(0.1)
        assert loading_windows() == 1, "notifications stacked"
        wait(lambda: state()["status"] == "ready", "tracked diff ready")
        assert nvim.exec_lua("return require('moonshine.diff').lualine_hunks()").startswith("hunks:")
        nvim.current.window.cursor = (2, 0)
        nvim.exec_lua("require('moonshine.diff').nav(-1)")
        assert nvim.current.window.cursor[0] == 1
        nvim.exec_lua("require('moonshine.diff').preview()")
        assert nvim.exec_lua("return vim.b.large_hunk_viewer and vim.bo.readonly")
        nvim.api.set_current_buf(buf)
        subprocess.run(["git", "-C", directory, "add", "tracked.txt"], check=True)
        wait(lambda: state()["status"] == "updating", "index watcher starts update")
        assert nvim.exec_lua("return require('moonshine.diff').lualine_hunks()") == "diff: updating…"
        wait(lambda: state()["status"] == "ready", "index update settles")
        assert nvim.exec_lua("return require('moonshine.diff').lualine_hunks()") == ""
        for file, expected in [(clean, "ready"), (missing, "unavailable")]:
            nvim.command("edit " + str(file))
            target = nvim.current.buffer.number
            wait(lambda: nvim.exec_lua("local s = require('mini.diff').get_buf_state(...); return s and s.status", target) == expected,
                 file.name + " settles")
            assert nvim.exec_lua("return require('moonshine.diff').lualine_hunks()") == ""
        print("minidiff feedback: configured UI smoke checks passed")
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass
