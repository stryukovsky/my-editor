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
    (temporary / "src/nested").mkdir(parents=True)
    (temporary / "src/nested/ui.lua").write_text("return {}\n")
    (temporary / "test/my-research").mkdir(parents=True)
    (temporary / "test/my-research/PoolManager.swap.t.sol").write_text("// fixture\n")
    nvim = pynvim.attach(
        "child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"]
    )

    def lua(code, *args):
        return nvim.exec_lua(code, *args)

    lua(
        """
      local root,override=...
      vim.opt.rtp:prepend(root)
      vim.opt.rtp:append(vim.fn.glob(root .. "/moonshine.nvim/*", true, true))
      for _,plugin in ipairs{'langmapper.nvim','friendly-snippets','material.nvim','lualine.nvim'} do
        vim.opt.rtp:append(root..'/data/lazy/'..plugin)
      end
      vim.opt.rtp:append(root..'/data/tree-sitter')
      vim.o.timeoutlen=50;vim.o.ttimeoutlen=10
      require('langmapper').setup{hack_keymap=false}
      require('configs.completion').setup_mappings()
      if override ~= '' then
        package.preload['moonshine.input.completion']=function() return dofile(override) end
      end
      require('moonshine.input').setup()
      require('terminal_reimagined')
      require('configs.material-theme')
      vim.o.background='light';vim.cmd.colorscheme('material-lighter')
      require('lualine').setup {
        options = {
          theme = 'auto', globalstatus = true,
          ignore_focus = function(win) return vim.api.nvim_win_get_config(win).relative ~= '' end,
        },
        sections = { lualine_a = {'mode'}, lualine_c = {function() return 'INPUT-STATUS' end} },
      }
      require('lualine').refresh {force=true}
      vim.go.statusline=vim.wo.statusline
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
    blank_status_frames = 0
    blank_input_frames = 0
    seen_input = False
    errors = []

    def redraw(method, updates):
        global seen_popup, blank_frames, blank_status_frames, blank_input_frames, seen_input
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
                    for row, line in enumerate(screen[:-1]):
                        if " Commit " in line:
                            text = screen[row + 1].split("│")[1].strip()
                            if seen_input and not text:
                                blank_input_frames += 1
                            seen_input = seen_input or bool(text)
                    visible = any("conventional commit" in row for row in screen)
                    if seen_popup and not visible:
                        blank_frames += 1
                    seen_popup = seen_popup or visible
                    if not any("INPUT-STATUS" in row for row in screen):
                        blank_status_frames += 1

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
                "_G.input_checks.delay=vim.o.autocompletedelay;_G.input_checks.docs=vim.bo.completeopt:find('popup',1,true)~=nil;_G.input_checks.insert_title=vim.api.nvim_win_get_config(0).title[1][1]",
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
            for token, expected, label in [
                ("ui", "ui.lua", "file"),
                ("nested", "nested", "folder"),
                ("(PoolManager", "(PoolManager.swap.t.sol", "filename"),
            ]:
                open_input()
                key("fix: " + token, 0.3)
                key("<C-n><CR>")
                call(
                    lua,
                    "local label,expected=...;_G.input_checks[label]=vim.api.nvim_get_current_line()==expected and _G.input_result=='pending'",
                    label,
                    "fix: " + expected,
                )
                key("<CR>", 0.25)
            open_input()
            call(lua, "vim.o.autocompletedelay=73")
            key("<Esc>")
            call(lua, "_G.input_checks.normal_title=vim.api.nvim_win_get_config(0).title[1][1]")
            key("q", 0.25)
            call(
                lua,
                "_G.input_checks.external=vim.o.autocompletedelay;_G.input_checks.cancelled=_G.input_result=='cancelled'",
            )
            open_input()
            call(lua, "vim.api.nvim_win_close(0,true)")
            time.sleep(0.25)
            call(lua, "_G.input_checks.closed=vim.o.autocompletedelay")
            call(
                lua,
                """
                _G.input_result='pending'
                vim.ui.input({prompt='Commit', filetype='gitcommit', cwd=..., multiline=true},
                  function(v) _G.input_result=v end)
                """,
                str(temporary),
            )
            time.sleep(0.25)
            key("docs: explain input")
            key("<CR>")
            key("<CR>")
            call(lua, "_G.input_checks.grown=vim.api.nvim_win_get_height(0)")
            key("<BS>")
            call(lua, "_G.input_checks.shrunk=vim.api.nvim_win_get_height(0)")
            key("<CR>")
            key("Describe the change.")
            key("<C-s>", 0.25)
            call(lua, "_G.input_checks.multiline=_G.input_result")
            call(lua, "vim.cmd.enew();vim.fn.jobstart({'cat'},{term=true});vim.cmd.startinsert()")
            time.sleep(0.2)
            call(lua, "vim.g.statusline_winid=vim.api.nvim_get_current_win();_G.input_checks.terminal_insert=require('terminal_reimagined').mode_label();_G.input_checks.terminal_winbar=vim.wo.winbar")
            key("<C-\\><C-n>")
            call(lua, "_G.input_checks.terminal_normal=require('terminal_reimagined').mode_label()")
        finally:
            nvim.async_call(nvim.stop_loop)

    threading.Thread(target=drive, daemon=True).start()
    try:
        nvim.run_loop(None, redraw)
        assert not errors, errors
        checks = lua("return _G.input_checks")
        assert seen_input and blank_input_frames == 0, f"typed text disappeared in {blank_input_frames} frames"
        assert checks["insert_title"] == " INSERT " and checks["normal_title"] == " NORMAL ", checks
        assert blank_status_frames == 0, f"lualine disappeared in {blank_status_frames} frames"
        assert seen_popup, "completion popup was never rendered"
        assert (
            blank_frames == 0
        ), f"popup visibly disappeared in {blank_frames} frames while typing"
        assert checks["delay"] == 0 and not checks["docs"], checks
        assert checks["snippet"] and checks["not_submitted"], checks
        assert checks["value"] == "feat(render): fix menu flicker", checks
        assert checks["file"] and checks["folder"], checks
        assert checks["filename"], checks
        assert checks["restored"] == 137, checks
        assert checks["external"] == 73 and checks["cancelled"], checks
        assert checks["closed"] == 73, checks
        assert checks["grown"] == 3 and checks["shrunk"] == 2, checks
        assert checks["multiline"] == "docs: explain input\n\nDescribe the change.", checks
        assert "leave terminal" in checks["terminal_insert"], checks
        assert "enter terminal" in checks["terminal_normal"], checks
        assert "mode_label" in checks["terminal_winbar"], checks
        assert lua("return vim.v.errmsg") == "", lua("return vim.v.errmsg")
        print(
            "PASS typed input stays visible during completion; popup and lualine stay visible; snippet acceptance and submission preserved"
        )
        print(
            "PASS completion delay restoration and terminal mode indicator preserved"
        )
        print("PASS changed file and parent folder completion acceptance in commit input")
        print("PASS multiline commit input grows, shrinks, and submits blank lines intact")
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass
