"""uv run --with pynvim python tests/markdown_math_preview_ui.py [config-root] [runtime-overlay]."""
import os
from pathlib import Path
import sys
import tempfile
import time

import pynvim

config = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.home() / '.config/nvim'
overlay = Path(sys.argv[2]).resolve() if len(sys.argv) > 2 else None
source = [
    '# Math table', '',
    '| Formula | Value |', '| --- | --- |',
    r'| $\frac{\sqrt{\alpha}}{\beta+\gamma}$ | $\psi(x)\leq\infty$ |',
    r'| 界 $\alpha$ and $\beta$ | $\left\lvert x\right\rvert$ |',
    r'| code `$\alpha$` | plain |', '',
    r'## After $\theta$', '',
    r'Before $\alpha + \beta$ after.', '',
    '$$', r'\sqrt{\frac{k}{c}}', '$$', '',
    '```latex', r'$\frac{a}{b}$', '```',
]
with tempfile.TemporaryDirectory(prefix='nvim-math-preview-') as directory:
    os.environ.update(XDG_STATE_HOME=directory+'/state', XDG_CACHE_HOME=directory+'/cache',
                      NVIM_LOG_FILE=directory+'/nvim.log')
    file = Path(directory) / 'math.md'
    original = '\n'.join(source) + '\n'
    file.write_text(original)
    nvim = pynvim.attach('child', argv=['nvim', '--embed', '-u', 'NONE', '-i', 'NONE', '-n'])
    nvim.ui_attach(100, 40, rgb=True)
    try:
        nvim.exec_lua('''
            local config, overlay = ...
            vim.opt.rtp:append(vim.fn.glob(config .. "/moonshine.nvim/*", true, true))
            for _, path in ipairs({'/data/tree-sitter', '/data/lazy/nvim-treesitter/runtime',
                '/data/lazy/render-markdown.nvim', ''}) do vim.opt.rtp:prepend(config .. path) end
            if type(overlay) == 'string' then vim.opt.rtp:prepend(overlay) end
            require 'configs.render-markdown'
            require('render-markdown.core.manager').init()
            require('render-markdown.core.preview').columns = 48
            vim.cmd('filetype on')
            vim.opt.number = false; vim.opt.signcolumn = 'no'; vim.opt.foldcolumn = '0'
            vim.opt.swapfile = false
        ''', str(config), str(overlay) if overlay else None)
        nvim.command('edit ' + str(file))
        nvim.exec_lua("vim.treesitter.start(0, 'markdown')")
        src = nvim.current.buffer.number
        undo = nvim.funcs.undotree()

        def wait(predicate, label):
            end = time.monotonic() + 4
            while time.monotonic() < end:
                if predicate():
                    return
                time.sleep(.02)
            raise AssertionError(label)

        def open_preview():
            nvim.exec_lua("require('render-markdown').preview(); require('render-markdown').buf_enable()")
            assert nvim.current.buffer.number != src
            return nvim.current.buffer.number

        dst = open_preview()
        wait(lambda: any('(√(α)) ÷ (β+γ)' in line for line in nvim.current.buffer[:]),
             'math was not materialized before table wrapping')
        lines = list(nvim.current.buffer[:])
        assert any('ψ(x)≤∞' in line for line in lines), lines
        assert any('∣ x∣' in line for line in lines), 'math bars became Markdown columns'
        assert 'Before  α + β  after.' in lines, 'prose did not use real compact Unicode'
        assert '## After  θ ' in lines, 'heading row was lost'
        assert '√((k) ÷ (c))' in lines and '' in lines
        assert r'$\frac{a}{b}$' in lines, 'fenced code was converted'
        assert any(r'`$\alpha$`' in line for line in lines), 'inline code was converted'
        assert not nvim.current.buffer.options['modifiable']

        def border_columns(text):
            return nvim.exec_lua(r'''
                local line = ...
                local cols, width = {}, 0
                for _, char in ipairs(vim.fn.split(line, [[\zs]])) do
                    for _, box in ipairs({'│','┌','┬','┐','├','┼','┤','└','┴','┘'}) do
                        if char == box then cols[#cols+1] = width; break end
                    end
                    width = width + vim.fn.strdisplaywidth(char)
                end
                return cols
            ''', text)

        grid = [line for line in lines if line.startswith(('┌', '│', '├', '└'))]
        expected = border_columns(grid[0])
        assert len(expected) == 3, 'unexpected number of table columns'
        for line in grid:
            assert nvim.funcs.strdisplaywidth(line) == 48, line
            assert border_columns(line) == expected, line

        time.sleep(.3)
        nvim.command('redraw!')
        # Verify pixels agree with buffer text. Previously the late math overlay
        # erased or shifted │ borders after the formatter had measured raw TeX.
        screen = nvim.exec_lua('''
            local result = {}
            for row=1,36 do
                local text = ''
                for col=1,100 do text = text .. vim.fn.screenstring(row,col) end
                result[#result+1] = text
            end
            return result
        ''')
        visible = [line for line in screen if line.startswith(('┌','│','├','└'))]
        assert len(visible) == len(grid)
        for line in visible:
            assert border_columns(line) == expected, ('screen borders misaligned', line)
        assert any('(√(α)) ÷ (β+γ)' in line for line in visible)
        assert not nvim.exec_lua('''
            local ns = vim.api.nvim_get_namespaces()['render-markdown.nvim']
            for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0,ns,0,-1,{details=true})) do
                local d = mark[4]
                if d.hl_group == 'RenderMarkdownMath' then return true end
                for _, text in ipairs(d.virt_text or {}) do
                    if text[2] == 'RenderMarkdownMath' then return true end
                end
            end
            return false
        '''), 'preview still uses late math overlays'

        nvim.exec_lua("require('render-markdown').preview()")
        assert nvim.current.buffer.number == src
        assert list(nvim.current.buffer[:]) == source
        assert not nvim.current.buffer.options['modified']
        assert nvim.funcs.undotree() == undo
        assert file.read_text() == original

        # Refresh performs conversion again before remeasuring the table.
        dst = open_preview()
        nvim.exec_lua('''
            local src, replacement = ...
            vim.api.nvim_buf_set_lines(src,4,5,false,{replacement})
            vim.api.nvim_exec_autocmds('TextChanged',{buffer=src})
        ''', src, source[4].replace(r'\alpha', r'\theta'))
        wait(lambda: any('(√(θ)) ÷ (β+γ)' in line for line in nvim.current.buffer[:]),
             'source edit did not refresh materialized math')
        for line in nvim.current.buffer[:]:
            if line.startswith(('┌','│','├','└')):
                assert nvim.funcs.strdisplaywidth(line) == 48
        assert file.read_text() == original
        print('PASS: real Unicode before table sizing/wrapping, aligned screen borders, math bars, code, headings, source/undo, no late overlays, refresh')
    finally:
        try:
            nvim.command('qa!')
        except EOFError:
            pass
