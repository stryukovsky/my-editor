"""Midword navigation/docs: uv run --with pynvim python tests/native_completion_navigation.py."""

import os
from pathlib import Path
import sys
import tempfile
import time

import pynvim

ROOT = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="completion-navigation-", dir="/tmp/opencode") as temp:
    os.environ["XDG_STATE_HOME"] = temp
    os.environ["NVIM_LOG_FILE"] = temp + "/nvim.log"
    nvim = pynvim.attach("child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"])

    def lua(code, *args):
        return nvim.exec_lua(code, *args)

    def keys(text):
        nvim.input(text)
        time.sleep(0.25)

    def wait(check):
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            if check():
                return
            time.sleep(0.025)
        raise AssertionError(lua("return {vim.fn.complete_info(),vim.v.errmsg}"))

    try:
        lua("""
          local root=...
          vim.opt.rtp:prepend(root)
          vim.opt.rtp:append(vim.fn.glob(root..'/moonshine.nvim/*',true,true))
          vim.opt.rtp:append(root..'/data/lazy/langmapper.nvim')
          vim.opt.rtp:append(root..'/data/lazy/render-markdown.nvim')
          vim.opt.rtp:append(root..'/data/tree-sitter')
          vim.o.virtualedit='onemore'
          require('langmapper').setup{hack_keymap=false}
          require('configs.render-markdown')
          require('configs.completion').setup_mappings()
          vim.api.nvim_set_current_line('print(value)')
          vim.api.nvim_win_set_cursor(0,{1,3})
          _G.navigation_events={}
          for _,event in ipairs{'CompleteChanged','CompleteDone','TextChangedP'} do
            vim.api.nvim_create_autocmd(event,{callback=function()
              table.insert(navigation_events,{event,vim.api.nvim_get_current_line(),vim.fn.complete_info({'selected'}).selected})
            end})
          end
        """, str(ROOT))
        nvim.api.ui_attach(100, 28, {"rgb": True})
        client = lua("""
          local python,script,root=...
          return vim.lsp.start{name='navigation',cmd={python,script,'--server'},root_dir=root,
            init_options={encoding='utf-16',events=root..'/events',completion={isIncomplete=false,items={
              {label='print',kind=3,documentation={kind='markdown',value='# Print\\n\\n**First** candidate'}},
              {label='printf',kind=3,documentation={kind='markdown',value='# Printf\\n\\n**Second** candidate'}},
              {label='printx',kind=3,documentation={kind='plaintext',value='# Literal\\n\\n**Not Markdown**'}},
            }}}}
        """, sys.executable, str(ROOT / "tests/native_completion_midword.py"), temp)
        wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client))
        keys("i<C-Space>")
        wait(lambda: lua("return vim.fn.pumvisible()") == 1)
        for key, expected in [("<C-j>", 0), ("<C-j>", 1), ("<C-j>", 2), ("<C-k>", 1),
                              ("<C-k>", 0), ("<C-k>", -1), ("<C-j>", 0)]:
            keys(key)
            actual = lua("return vim.fn.complete_info({'selected'}).selected")
            assert actual == expected, (key, actual, lua("return navigation_events"))
            assert nvim.current.line == "print(value)", (key, nvim.current.line)
            if expected == 2:
                assert lua("""
                  local buf=vim.fn.complete_info({'selected'}).preview_bufnr
                  local ns=vim.api.nvim_get_namespaces()['render-markdown.nvim']
                  return #vim.api.nvim_buf_get_extmarks(buf,ns,0,-1,{})==0
                """), "plaintext documentation retained Markdown decorations"
        assert not lua("return vim.tbl_contains(vim.tbl_map(function(e) return e[1] end,navigation_events),'CompleteDone')"), "menu restarted during navigation"
        preview = lua("return vim.fn.complete_info()")
        assert preview.get("preview_winid", 0) > 0
        border = lua("return vim.api.nvim_win_get_config(...).border", preview["preview_winid"])
        assert border and border[0] == "╭", border
        wait(lambda: lua("return #vim.api.nvim_buf_get_extmarks(...,vim.api.nvim_get_namespaces()['render-markdown.nvim'],0,-1,{}) > 0", preview["preview_bufnr"]))
        keys("<CR>")
        assert nvim.current.line == "print(value)", nvim.current.line
        assert not lua("return vim.v.errmsg"), lua("return vim.v.errmsg")
        assert lua("return #vim.lsp.get_clients{bufnr=0}") == 1, "documentation attached an extra LSP to the source"
        print("PASS stable Ctrl-J/Ctrl-K midword selection, rounded rendered documentation, acceptance")

        keys("<Esc>")
        lua("vim.lsp.stop_client(...,true);vim.cmd.enew{bang=true};vim.api.nvim_set_current_line('imp')", client)
        client = lua("""
          local python,script,root=...
          return vim.lsp.start{name='resolved-navigation',cmd={python,script,'--server'},root_dir=root,
            init_options={mode='accept',events=root..'/resolved.events'}}
        """, sys.executable, str(ROOT / "tests/native_completion_integration.py"), temp)
        wait(lambda: lua("local c=vim.lsp.get_client_by_id(...);return c and c.initialized", client))
        keys("A<C-Space>")
        wait(lambda: lua("return vim.fn.pumvisible()") == 1)
        keys("<C-j>")
        wait(lambda: lua("""
          local info=vim.fn.complete_info({'selected'})
          if not info.preview_winid then return false end
          local border=vim.api.nvim_win_get_config(info.preview_winid).border
          local ns=vim.api.nvim_get_namespaces()['render-markdown.nvim']
          return type(border)=='table' and border[1]=='╭' and ns
            and #vim.api.nvim_buf_get_extmarks(info.preview_bufnr,ns,0,-1,{})>0
        """))
        assert nvim.current.line == "imp", nvim.current.line
        assert not lua("return vim.v.errmsg"), lua("return vim.v.errmsg")
        print("PASS asynchronously resolved documentation renders with rounded borders")
    finally:
        try:
            nvim.command("qa!")
        except (EOFError, OSError):
            pass
