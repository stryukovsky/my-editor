"""uv run --with pynvim python tests/markdown_heading_navigation_ui.py [config-root]."""
import os
from pathlib import Path
import sys
import tempfile
import time

import pynvim

config = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.home() / '.config/nvim'
with tempfile.TemporaryDirectory(prefix='nvim-heading-navigation-') as directory:
    for name, suffix in [('XDG_STATE_HOME', 'state'), ('XDG_CACHE_HOME', 'cache'),
                         ('XDG_RUNTIME_DIR', ''), ('NVIM_LOG_FILE', 'nvim.log')]:
        os.environ[name] = str(Path(directory) / suffix)
    file = Path(directory) / 'headings.md'
    lines = ['intro', '', '# Same', '', 'first body', '', '| A | B |', '| --- | --- |',
             '| ' + 'table words ' * 25 + ' | ' + 'more cells ' * 20 + ' |', '',
             '## Nested', 'nested body', '', '```markdown', '# Not a heading', '```', '',
             '# Same', 'second body', 'more body', '', 'Setext heading', '---', 'last body']
    original = '\n'.join(lines) + '\n'
    file.write_text(original)
    nvim = pynvim.attach('child', argv=['nvim', '--embed', '-u', 'NONE', '-i', 'NONE', '-n'])
    nvim.ui_attach(120, 45, rgb=True)
    try:
        nvim.exec_lua('''
            local config = ...
            for _, path in ipairs({ '/data/tree-sitter', '/data/lazy/nvim-treesitter/runtime',
                '/data/lazy/render-markdown.nvim', '/data/lazy/langmapper.nvim', '/data/lazy/plenary.nvim',
                '/data/lazy/nvim-web-devicons', '/data/lazy/nvim-notify', '' }) do
                vim.opt.rtp:prepend(config .. path)
            end
            vim.g.mapleader = ' '
            require 'configs.langmapper'
            require 'configs.render-markdown'
            require('render-markdown.core.manager').init()
            require 'mappings.markdownpreview'
            vim.api.nvim_create_autocmd('FileType', {pattern = 'markdown', callback = function(a)
                vim.treesitter.start(a.buf)
            end})
            vim.cmd('filetype on')
            vim.opt.swapfile = false
        ''', str(config))
        nvim.command('edit ' + str(file))
        src = nvim.current.buffer.number
        pw = nvim.current.window.handle
        undo = nvim.funcs.undotree()
        nvim.command('vsplit')
        sw = nvim.current.window.handle

        def wait(predicate, label):
            until = time.monotonic() + 5
            while time.monotonic() < until:
                if predicate():
                    return
                time.sleep(.02)
            raise AssertionError(label)

        def press(keys):
            nvim.input(keys)
            nvim.eval('1')

        def cursor(win):
            return list(nvim.api.win_get_cursor(win))

        def move(win, row):
            nvim.api.set_current_win(win)
            press(str(row) + 'G')
            wait(lambda: cursor(win)[0] == row, 'cursor input')

        move(pw, 12)
        press(' mdr')
        wait(lambda: nvim.current.buffer.number != src, 'mapped preview opening')
        dst = nvim.current.buffer.number

        def preview_heading(index):
            return nvim.exec_lua('return require("render-markdown.core.preview").docs[...].headings['
                                 + str(index) + '].preview_row + 1', src)

        wait(lambda: cursor(pw)[0] == preview_heading(2), 'initial nested heading')
        assert nvim.exec_lua("return vim.api.nvim_win_get_buf(...)", sw) == src
        move(sw, 19)
        wait(lambda: cursor(pw)[0] == preview_heading(3), 'source drives second duplicate heading')
        assert cursor(sw)[0] == 19
        move(sw, 20)
        assert cursor(pw)[0] == preview_heading(3), 'same-section movement changed peer'
        move(pw, preview_heading(2) + 1)
        wait(lambda: cursor(sw)[0] == 11, 'preview drives nested source heading')
        assert cursor(pw)[0] == preview_heading(2) + 1, 'reciprocal cursor jump'
        move(pw, preview_heading(3) + 1)
        press(' mdr')
        wait(lambda: nvim.current.buffer.number == src, 'mapped return to source')
        assert cursor(pw)[0] == 18
        assert list(nvim.current.buffer[:]) == lines
        assert nvim.funcs.undotree() == undo
        assert file.read_text() == original

        # Exercise a real source edit followed by reopening at its new section.
        move(pw, 19)
        press('A updated<Esc>')
        wait(lambda: nvim.current.buffer[18].endswith('updated'), 'source edit')
        press(' mdr')
        wait(lambda: nvim.current.buffer.number != src, 'reopen after edit')
        wait(lambda: cursor(pw)[0] == preview_heading(3), 'updated heading anchor')
        assert any('updated' in line for line in nvim.current.buffer[:])
        print('heading navigation UI: mapped open/close, source/preview section follow, duplicate and nested headings, tables, code fences, Setext, no bounce, source preservation, edits and reopen passed')
    finally:
        try:
            nvim.command('qa!')
        except (EOFError, OSError):
            pass
