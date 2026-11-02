"""Automatic typing/UI regression: uv run --with pynvim python tests/native_completion_typing.py."""

import os
from pathlib import Path
import sys
import tempfile
import threading
import time

import pynvim

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="completion-typing-") as temp:
    directory = Path(temp)
    (directory / "state/nvim").mkdir(parents=True)
    os.environ["XDG_STATE_HOME"] = str(directory / "state")
    os.environ["NVIM_LOG_FILE"] = str(directory / "nvim.log")
    nvim = pynvim.attach("child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"])
    def lua(code, *args):
        return nvim.exec_lua(code, *args)
    lua("""
      local root=...
      vim.opt.rtp:prepend(root)
      vim.opt.rtp:append(root..'/data/lazy/langmapper.nvim')
      vim.o.virtualedit='onemore';vim.o.timeoutlen=50;vim.o.ttimeoutlen=10
      vim.o.showmode=true
      require('langmapper').setup{hack_keymap=false}
      require('configs.completion').setup_mappings()
    """, str(root))
    nvim.api.ui_attach(90, 25, {"rgb": True, "ext_linegrid": True, "ext_messages": True})
    messages, errors = [], []
    grids = {}
    checks = {}

    def rpc(function, *args):
        done = threading.Event()
        result = []
        def execute():
            try:
                result.append((True, function(*args)))
            except Exception as error:
                result.append((False, error))
            finally:
                done.set()
        nvim.async_call(execute)
        assert done.wait(8), "RPC timeout"
        if not result[0][0]:
            raise result[0][1]
        return result[0][1]

    def lua(code, *args):
        return rpc(nvim.exec_lua, code, *args)

    def strings(value):
        if isinstance(value, str):
            return value
        if isinstance(value, list):
            return "".join(strings(item) for item in value)
        return ""

    def redraw(method, updates):
        if method == "redraw":
            for update in updates:
                if update[0].startswith("msg_"):
                    messages.append(strings(update[1:]))
                for value in update[1:]:
                    if update[0] == "grid_resize":
                        grid, width, height = value
                        grids[grid] = [[" "] * width for _ in range(height)]
                    elif update[0] == "grid_clear" and value[0] in grids:
                        grid = value[0]
                        grids[grid] = [[" "] * len(row) for row in grids[grid]]
                    elif update[0] == "grid_line":
                        grid, row, col, cells = value[:4]
                        for cell in cells:
                            for _ in range(cell[2] if len(cell) > 2 else 1):
                                grids[grid][row][col] = cell[0]
                                col += 1
                if update[0] == "flush":
                    for grid in grids.values():
                        messages.extend("".join(row) for row in grid if "not found" in "".join(row))

    def keys(value, delay=0.25):
        rpc(nvim.input, value)
        time.sleep(delay)

    def wait(check, label):
        until = time.monotonic() + 5
        while time.monotonic() < until:
            if check():
                return
            time.sleep(0.025)
        raise AssertionError(label)

    def drive():
        try:
            # Manual no-match retries must stay quiet too.
            lua("vim.cmd.enew{bang=true};vim.bo.filetype='text';vim.bo.autocomplete=false")
            keys("i")
            for character in "zxqv":
                keys(character)
                keys("<C-Space>")
            checks["unmatched"] = lua("return vim.api.nvim_get_current_line()") == "zxqv"
            keys("<Esc>")
            lua("vim.cmd.enew{bang=true};vim.api.nvim_set_current_line('nt(value)');vim.bo.filetype='text'")
            client = lua("""
              local python,script,root,events=...
              return vim.lsp.start{name='typing-fixture',cmd={python,script,'--server'},root_dir=root,
                init_options={encoding='utf-16',events=events,
                  completion={isIncomplete=false,items={{label='print',kind=3,insertText='print'}}}}}
            """, sys.executable, str(root / "tests/native_completion_midword.py"), str(directory), str(directory / "events"))
            wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client), "LSP initialization")
            lua("vim.api.nvim_win_set_cursor(0,{1,0})")
            keys("i")
            for character in "pri":
                keys(character)
                wait(lambda: lua("return vim.fn.pumvisible()") == 1, "automatic LSP popup")
            checks["typed"] = lua("return vim.api.nvim_get_current_line()") == "print(value)"
            keys("<C-n><CR>")
            checks["accepted"] = lua("return vim.api.nvim_get_current_line()=='print(value)' and vim.deep_equal(vim.api.nvim_win_get_cursor(0),{1,5})")
            # Return to automatic buffer-word completion without LSP.
            keys("<Esc>")
            lua("vim.cmd.enew{bang=true};vim.bo.filetype='text'")
            keys("i")
            for character in "vqzx":
                keys(character)
            checks["errors"] = lua("return vim.v.errmsg")
        except Exception as error:
            errors.append(error)
        finally:
            nvim.async_call(nvim.stop_loop)

    threading.Thread(target=drive, daemon=True).start()
    try:
        nvim.run_loop(None, redraw)
        assert not errors, errors
        assert checks.get("unmatched") and checks.get("typed") and checks.get("accepted"), checks
        assert not checks["errors"], checks
        noisy = [message for message in messages if "pattern not found" in message.lower() or "scanning" in message.lower()]
        assert not noisy, noisy
        print("PASS per-letter automatic completion is quiet; automatic LSP popup and midword acceptance work")
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass
