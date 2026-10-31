"""uv run --with pynvim python tests/markdown_math_ui.py [config-root]."""
import os
from pathlib import Path
import sys
import tempfile
import time

import pynvim

config = Path.home() / '.config/nvim'
root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else config
with tempfile.TemporaryDirectory(prefix='nvim-math-') as directory:
    os.environ['XDG_STATE_HOME'] = directory + '/state'
    os.environ['XDG_CACHE_HOME'] = directory + '/cache'
    source = '\n'.join([
        r'unicode Ж $\alpha \cdot x \Rightarrow \infty$',
        r'$\left\langle x \right\rangle \sin x$',
        r'`$\alpha$`', '```latex', r'$\alpha$', '```',
        r'$x^2 a_i \hat{x} \frac{1}{x} \unknown \alphabogus \\alpha$',
        '', '$$', r'\theta \to \Omega', '$$', '', 'cursor',
    ]) + '\n'
    file = Path(directory) / 'math.md'
    file.write_text(source)
    nvim = pynvim.attach('child', argv=['nvim', '--embed', '-u', 'NONE', '-i', 'NONE', '-n'])
    nvim.ui_attach(100, 30, rgb=True)
    try:
        nvim.exec_lua('''
            local root, config = ...
            vim.opt.rtp:prepend(config .. '/data/tree-sitter')
            vim.opt.rtp:prepend(config .. '/data/lazy/nvim-treesitter/runtime')
            vim.opt.rtp:prepend(config .. '/data/lazy/render-markdown.nvim')
            vim.opt.rtp:prepend(config)
            vim.opt.rtp:prepend(root)
            require 'configs.render-markdown'
            require('render-markdown.core.manager').init()
            require 'highlight'
            vim.api.nvim_set_hl(0, 'Normal', {fg=0xd8c8aa, bg=0x181818})
            vim.api.nvim_exec_autocmds('ColorScheme', {})
            vim.cmd('filetype on')
            vim.opt.number = false
            vim.opt.signcolumn = 'no'
            vim.opt.foldcolumn = '0'
            vim.opt.swapfile = false
        ''', str(root), str(config))
        nvim.command('edit ' + str(file))
        nvim.exec_lua("vim.treesitter.start(0, 'markdown')")
        nvim.current.window.cursor = (13, 0)
        buf = nvim.current.buffer.number
        undo = nvim.funcs.undotree()

        def screen(width=100):
            time.sleep(.3)
            nvim.command('redraw!')
            return nvim.exec_lua('''
                local width = ...
                local lines = {}
                for row=1,27 do
                    local line = ''
                    for col=1,width do line = line .. vim.fn.screenstring(row,col) end
                    lines[#lines+1] = line
                end
                return lines
            ''', width)

        def rendered():
            lines = screen()
            assert lines[0].strip() == 'unicode Ж  α ⋅ x ⇒ ∞', lines[0]
            assert lines[1].strip() == '⟨ x ⟩ sin x', lines[1]
            assert lines[2].strip() == r'`$\alpha$`', lines[2]
            assert lines[3].strip() == '```latex', lines[3]
            assert lines[4].strip() == r'$\alpha$', lines[4]
            assert lines[5].strip() == '```', lines[5]
            assert lines[6].strip() == r'x^2 a_i \hat{x} (1) ÷ (x) \unknown \alphabogus \\alpha', lines[6]
            assert lines[8].strip() == '' and lines[10].strip() == '', 'display delimiter icon/spaces'
            assert lines[9].strip() == 'θ → Ω', lines[9]
            assert nvim.current.window.options['conceallevel'] == 2

        # Respect the user's configured default. When rendering starts disabled,
        # verify literal source first, then explicitly enable this buffer.
        if not nvim.exec_lua("return require('render-markdown').get()"):
            assert screen()[0].strip() == source.splitlines()[0]
            nvim.exec_lua("require('render-markdown').buf_enable()")
        rendered()
        # Source math and replacements use the Normal foreground, even when the
        # theme colors @markup.math blue and the global Conceal group gray.
        nvim.exec_lua('''
            vim.api.nvim_set_hl(0, '@markup.math', {fg=0x0088ff})
            vim.api.nvim_set_hl(0, 'Conceal', {fg=0x888888})
        ''')
        screen()
        normal_fg = nvim.api.get_hl(0, {'name': 'Normal'})['fg']
        math_fg = nvim.api.get_hl(0, {'name': 'RenderMarkdownMath'})['fg']
        assert normal_fg == math_fg
        # screenattr covers the resulting UI cells, including virtual text.
        attrs = [nvim.funcs.screenattr(1, col) for col in (11, 12, 14, 16, 18, 20)]
        assert len(set(attrs)) == 1, ('inconsistent formula colors', attrs)
        for fg in (0x4b4031, 0xd8c8aa):
            nvim.exec_lua('''
                vim.api.nvim_set_hl(0, 'Normal', {fg=...})
                vim.api.nvim_exec_autocmds('ColorScheme', {})
            ''', fg)
            screen()
            assert nvim.api.get_hl(0, {'name': 'RenderMarkdownMath'})['fg'] == fg

        assert not nvim.current.buffer.options['modified']
        assert nvim.funcs.undotree() == undo
        nvim.command('silent write')
        assert file.read_text() == source
        nvim.current.window.cursor = (1, 12)
        assert 'α ⋅ x ⇒ ∞' in screen()[0], 'cursor line lost rendering'
        nvim.current.window.cursor = (13, 0)
        nvim.exec_lua("require('render-markdown').buf_toggle()")
        lines = screen()
        assert lines[0].strip() == source.splitlines()[0]
        assert nvim.current.window.options['conceallevel'] == 0
        assert nvim.exec_lua('''
            local ns = vim.api.nvim_get_namespaces()['render-markdown.nvim']
            return #vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{})
        ''') == 0
        nvim.exec_lua("require('render-markdown').buf_toggle()")
        rendered()
        nvim.current.buffer[0] = r'unicode Ж $\beta \cdot x \Rightarrow \infty$'
        nvim.exec_lua("vim.api.nvim_exec_autocmds('TextChanged',{buffer=0})")
        assert screen()[0].strip() == 'unicode Ж  β ⋅ x ⇒ ∞'
        nvim.current.window.cursor = (1, 0)
        nvim.ui_try_resize(28, 30)
        nvim.command('normal! zt')
        narrow = '\n'.join(screen(28))
        assert 'β ⋅ x ⇒ ∞' in ' '.join(narrow.split()) and r'`$\alpha$`' in narrow, narrow
        nvim.ui_try_resize(100, 30)
        # The custom preview filetype uses the same renderer.
        nvim.current.buffer.options['filetype'] = 'todotxt-preview'
        nvim.exec_lua("require('render-markdown').buf_enable()")
        assert screen()[0].strip() == 'unicode Ж  β ⋅ x ⇒ ∞'
        nvim.command('vnew')
        nvim.current.buffer.options['filetype'] = 'lua'
        nvim.current.buffer[:] = [r'local alpha = "\alpha"']
        nvim.exec_lua("vim.treesitter.start(0, 'lua')")
        assert nvim.exec_lua('''
            local hl = vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()]
            return hl:get_query('lua'):query() == vim.treesitter.query.get('lua','highlights')
        '''), 'unrelated buffer query changed'
        assert nvim.current.buffer[0] == r'local alpha = "\alpha"'
        if len(sys.argv) > 2:
            note = Path(sys.argv[2])
            note_bytes = note.read_bytes()
            note_lines = note.read_text().splitlines()
            nvim.command('only!')
            nvim.command('edit! ' + nvim.funcs.fnameescape(str(note)))
            nvim.exec_lua("vim.treesitter.start(0, 'markdown')")
            nvim.exec_lua("require('render-markdown').buf_enable()")
            screen()  # Let initial attachment settle before scrolling the larger note.
            for needle, expected in [
                (r'f(x)=\frac{k}{x}', "f(x)=(k) ÷ (x)"),
                (r'\psi(x,y)=\sqrt{xy}', "ψ(x,y)=√(xy)"),
                (r"V'(c)=\sqrt{\frac{k}{c}}", "V'(c)=√((k) ÷ (c))"),
                (r'q_\gamma(a)=', "q_γ(a)=(yγ a) ÷ (x+γ a)"),
            ]:
                row = next(i + 1 for i, line in enumerate(note_lines) if needle in line)
                nvim.input(str(row) + 'Gzt')
                view = '\n'.join(screen())
                assert expected in view, (expected, view)
            assert not nvim.current.buffer.options['modified']
            assert note.read_bytes() == note_bytes
            print('AMM vault note: real display and unchanged source passed')
        print('markdown math UI: configured default, enable, symbols, code, source/save/undo, cursor, toggles, edits, wraps, preview and buffer isolation passed')
    finally:
        try:
            nvim.command('qa!')
        except EOFError:
            pass
