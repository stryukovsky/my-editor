"""uv run --with pynvim python tests/native_completion_loading.py"""
from pathlib import Path
import sys
import time

import pynvim

root = Path(__file__).resolve().parents[1]
nvim = pynvim.attach("child", argv=["nvim", "--embed", "--headless", "-u", "NONE", "-i", "NONE"])


def lua(code, *args):
    return nvim.exec_lua(code, *args)


def wait(check, label):
    until = time.monotonic() + 15
    while time.monotonic() < until:
        if check():
            return
        time.sleep(0.01)
    raise AssertionError(label)


try:
    lua("""
      local root,python=...
      vim.opt.rtp:prepend(root)
      vim.opt.rtp:append(vim.fn.glob(root..'/moonshine.nvim/*',true,true))
      vim.opt.rtp:append(root..'/data/lazy/langmapper.nvim')
      require('langmapper').setup{hack_keymap=false}
      require('configs.completion').setup_mappings()
      vim.o.virtualedit='onemore'
      vim.api.nvim_buf_set_name(0, '/tmp/opencode/completion-loading.lua')
      vim.api.nvim_buf_set_lines(0,0,-1,false,{'imported'})
      vim.api.nvim_win_set_cursor(0,{1,8})
      _G.loading_client=vim.lsp.start{
        name='loading-fixture',cmd={python,root..'/tests/native_completion_integration.py','--server'},
        root_dir=root,init_options={mode='many',count=12000},
      }
    """, str(root), sys.executable)
    nvim.api.ui_attach(90, 25, {"rgb": True, "ext_linegrid": True})
    wait(lambda: lua("return vim.lsp.get_client_by_id(loading_client).initialized"), "initialize")
    nvim.input("A")
    wait(lambda: lua("return vim.fn.mode()") == "i", "insert")
    lua("""
      local select=require('native_completion.loading').select
      require('native_completion.loading').select=function(...)
        _G.loading_started=true
        return select(...)
      end
    """)
    nvim.input("<C-Space>")
    wait(lambda: lua("return loading_started == true"), "large response arrived")
    # RPC and typed input must be handled while batches are still pending.
    assert lua("return vim.fn.pumvisible()") == 0, "processing must yield before native popup"
    nvim.input("9")
    wait(lambda: lua("return vim.api.nvim_get_current_line()") == "imported9", "typing while loading")
    wait(lambda: lua("return vim.fn.pumvisible()") == 1, "fresh filtered popup")
    words = lua("return vim.tbl_map(function(x) return x.word end, vim.fn.complete_info({'items'}).items)")
    assert 0 < len(words) <= 200
    assert all("9" in word for word in words), "stale response must not overwrite fresh input"
    nvim.input("<Down><CR>")
    wait(lambda: lua("return vim.fn.pumvisible()") == 0, "native acceptance")
    assert lua("return vim.api.nvim_get_current_line()") in words
    assert not lua("return vim.v.errmsg"), lua("return vim.v.errmsg")
    print("PASS 12,000-item response yields to RPC/typing; stale work cancelled; popup bounded; native acceptance")
finally:
    try:
        nvim.command("qa!")
    except (EOFError, OSError):
        pass
