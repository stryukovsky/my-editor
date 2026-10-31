"""UI regression: uv run --with pynvim python tests/native_input_completion.py."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time

import pynvim

root = Path(sys.argv[1] if len(sys.argv) > 1 else Path(__file__).resolve().parents[1])
with tempfile.TemporaryDirectory(prefix="input-completion-") as directory:
    temporary = Path(directory)
    (temporary / "state/nvim").mkdir(parents=True)
    os.environ["XDG_STATE_HOME"] = str(temporary / "state")
    os.environ["NVIM_LOG_FILE"] = str(temporary / "nvim.log")
    subprocess.run(
        ["git", "init", "-q", "-b", "topic/input-render", str(temporary)], check=True
    )
    nvim = pynvim.attach(
        "child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"]
    )

    def lua(code, *args):
        return nvim.exec_lua(code, *args)

    lua(
        """
      local root,override=...
      vim.opt.rtp:prepend(root)
      for _,plugin in ipairs{'langmapper.nvim','friendly-snippets','material.nvim'} do
        vim.opt.rtp:append(root..'/data/lazy/'..plugin)
      end
      vim.opt.rtp:append(root..'/data/tree-sitter')
      vim.o.timeoutlen=50;vim.o.ttimeoutlen=10
      require('langmapper').setup{hack_keymap=false}
      require('configs.completion').setup_mappings()
      if override ~= '' then
        package.preload['configs.input_completion']=function() return dofile(override) end
      end
      require('configs.input').setup()
      require('configs.material-theme')
      vim.o.background='light';vim.cmd.colorscheme('material-lighter')
      vim.o.autocompletedelay=137
      _G.input_checks={}
      _G.input_result='pending'
    """,
        str(root),
        os.environ.get("NVIM_INPUT_COMPLETION_FILE", ""),
    )
    # Use the native renderer, not external popupmenu events. An internal hide/show
    # is harmless if it stays in one frame; an actually flushed blank frame is not.
    nvim.api.ui_attach(100, 30, {"rgb": True, "ext_linegrid": True})
    grids = {}
    phase = "setup"
    seen_popup = False
    blank_frames = 0
    errors = []

    def redraw(method, updates):
        global seen_popup, blank_frames
        if method != "redraw":
            return
        for update in updates:
            event = update[0]
            for value in update[1:]:
                if event == "grid_resize":
                    grid, width, height = value
                    grids[grid] = [[" "] * width for _ in range(height)]
                elif event == "grid_clear" and value[0] in grids:
                    grid = value[0]
                    grids[grid] = [[" "] * len(row) for row in grids[grid]]
                elif event == "grid_line":
                    grid, row, column, cells = value[:4]
                    for cell in cells:
                        for _ in range(cell[2] if len(cell) > 2 else 1):
                            grids[grid][row][column] = cell[0]
                            column += 1
                elif event == "flush" and phase == "typing":
                    screen = ["".join(row) for row in grids.get(1, [])]
                    visible = any("conventional commit" in row for row in screen)
                    if seen_popup and not visible:
                        blank_frames += 1
                    seen_popup = seen_popup or visible

    def call(function, *args):
        def execute():
            try:
                function(*args)
            except Exception as error:
                errors.append(error)

        nvim.async_call(execute)

    def key(text, delay=0.12):
        call(nvim.input, text)
        time.sleep(delay)

    def open_input():
        call(
            lua,
            "_G.input_result='pending';vim.ui.input({prompt='Commit',filetype='gitcommit',cwd=...},function(v) _G.input_result=v or 'cancelled' end)",
            str(temporary),
        )
        time.sleep(0.25)

    def drive():
        global phase
        try:
            open_input()
            call(
                lua,
                "_G.input_checks.delay=vim.o.autocompletedelay;_G.input_checks.docs=vim.bo.completeopt:find('popup',1,true)~=nil",
            )
            phase = "typing"
            for character in "feat":
                key(character, 0.2)
            time.sleep(0.25)
            phase = "acceptance"
            key("<C-n>")
            key("<CR>")
            call(
                lua,
                "_G.input_checks.snippet=vim.snippet.active();_G.input_checks.not_submitted=_G.input_result=='pending'",
            )
            key("render")
            key("<Tab>")
            key("fix menu flicker")
            key("<CR>", 0.25)
            call(
                lua,
                "_G.input_checks.value=_G.input_result;_G.input_checks.restored=vim.o.autocompletedelay",
            )
            open_input()
            call(lua, "vim.o.autocompletedelay=73")
            key("<Esc>")
            key("q", 0.25)
            call(
                lua,
                "_G.input_checks.external=vim.o.autocompletedelay;_G.input_checks.cancelled=_G.input_result=='cancelled'",
            )
            open_input()
            call(lua, "vim.api.nvim_win_close(0,true)")
            time.sleep(0.25)
            call(lua, "_G.input_checks.closed=vim.o.autocompletedelay")
        finally:
            nvim.async_call(nvim.stop_loop)

    threading.Thread(target=drive, daemon=True).start()
    try:
        nvim.run_loop(None, redraw)
        assert not errors, errors
        checks = lua("return _G.input_checks")
        assert seen_popup, "completion popup was never rendered"
        assert (
            blank_frames == 0
        ), f"popup visibly disappeared in {blank_frames} frames while typing"
        assert checks["delay"] == 0 and not checks["docs"], checks
        assert checks["snippet"] and checks["not_submitted"], checks
        assert checks["value"] == "feat(render): fix menu flicker", checks
        assert checks["restored"] == 137, checks
        assert checks["external"] == 73 and checks["cancelled"], checks
        assert checks["closed"] == 73, checks
        assert lua("return vim.v.errmsg") == "", lua("return vim.v.errmsg")
        print(
            "PASS native popup stays visible across typed characters; snippet acceptance and submission preserved"
        )
        print(
            "PASS completion delay restored on submit, cancel and window close; external option changes preserved"
        )
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass
