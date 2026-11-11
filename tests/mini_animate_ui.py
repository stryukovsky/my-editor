"""uv run --with pynvim python tests/mini_animate_ui.py (from config root)."""
import os, time, tempfile
import pynvim
root = os.getcwd()
with tempfile.TemporaryDirectory() as tmp:
    os.environ['NVIM_LOG_FILE'] = tmp + '/nvim.log'
    n = pynvim.attach('child', argv=['nvim', '--embed', '-u', 'NONE', '-i', 'NONE', '-n'])
    try:
        n.ui_attach(100, 32, rgb=True)
        n.exec_lua('''
            local root = ...
            vim.opt.rtp:prepend(root)
            vim.opt.rtp:append(root .. '/moonshine.nvim/mini_animate')
            vim.opt.rtp:append(root .. '/data/lazy/langmapper.nvim')
            require('configs.minianimate')
            local map = require 'mappings.map'
            map('n', 'zz', function() require('integrations.mini_animate').center_vertical(vim.v.count) end)
            map('n', 'zx', function() require('integrations.mini_animate').center_horizontal() end)
            vim.wo.wrap = false
            vim.wo.number = false
            vim.wo.signcolumn = 'no'
            vim.o.scrolloff = 0
            vim.o.sidescrolloff = 0
            vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.fn['repeat']({string.rep('x', 500)}, 500))
            vim.g.scroll_done = 0
            vim.api.nvim_create_autocmd('User', {pattern='MiniAnimateDoneScroll', callback=function() vim.g.scroll_done = vim.g.scroll_done + 1 end})
        ''', root)
        def view():
            return n.exec_lua('return vim.fn.winsaveview()')
        def settle():
            time.sleep(.4)
        settle()
        for keys in ['<C-d>', '<C-u>']:
            before = view()
            done = n.vars['scroll_done']
            n.input(keys)
            samples=[]
            for _ in range(40):
                samples.append(view()['topline'])
                time.sleep(.01)
            assert n.vars['scroll_done'] == done, (keys, samples)
            assert len(set(samples)) == 1, (keys, samples)
            assert not n.exec_lua('return MiniAnimate.is_active("scroll") or MiniAnimate.is_active("cursor")')
            assert view()['topline'] != before['topline']
        n.exec_lua('vim.api.nvim_win_set_cursor(0, {100, 0}); vim.cmd("normal! zt")')
        settle()
        done=n.vars['scroll_done']
        n.input('zz')
        samples=[]
        for _ in range(40):
            samples.append(view()['topline'])
            time.sleep(.01)
        assert len(set(samples)) > 2, samples
        assert view()['lnum'] == 100, view()
        n.input('120zz')
        settle()
        assert view()['lnum'] == 120, view()
        n.exec_lua('vim.api.nvim_win_set_cursor(0, {100, 0}); vim.cmd("normal! zt")')
        n.input('zz')
        time.sleep(.06)
        n.input('j')
        time.sleep(.05)
        stopped = view()
        settle()
        assert view() == stopped, ('vertical cancel', stopped, view())
        n.exec_lua('vim.api.nvim_win_set_cursor(0, {100, 250}); vim.cmd("normal! zs")')
        settle()
        before=view()
        expected=n.exec_lua('local v=vim.fn.winsaveview(); vim.cmd("normal! zszH"); local target=vim.fn.winsaveview(); vim.fn.winrestview(v); return target')
        n.input('zx')
        samples=[]
        for _ in range(40):
            samples.append(view()['leftcol'])
            time.sleep(.01)
        assert view()['leftcol'] == expected['leftcol'], (before, expected, view(), samples)
        assert len(set(samples)) > 2, samples
        assert view()['col'] == before['col']
        n.exec_lua('vim.cmd("normal! zs")')
        settle()
        n.input('zx')
        time.sleep(.06)
        n.input('h')
        time.sleep(.05)
        stopped=view()
        settle()
        assert view()['leftcol'] == stopped['leftcol'], ('cancel', stopped, view())
        n.exec_lua('vim.g.minianimate_disable=true; vim.cmd("normal! zs")')
        n.input('zx')
        settle()
        assert view()['leftcol'] == expected['leftcol'] - 1, view()
        assert n.exec_lua('''
            for _, kind in ipairs({'cursor', 'scroll', 'resize', 'open', 'close'}) do
                if MiniAnimate.config[kind].enable then return false end
            end
            return true
        '''), 'automatic animations must be disabled'
        print('PASS: only zz/zx animate; native half-page scrolling stays instant; centering preserves counts, cancels on navigation, and respects disable flag')
    finally:
        n.close()
