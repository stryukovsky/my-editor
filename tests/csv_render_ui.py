"""uv run --with pynvim python tests/csv_render_ui.py [config-root]."""
import os
from pathlib import Path
import sys
import tempfile
import time

import pynvim

root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()
with tempfile.TemporaryDirectory(prefix='csv-render-ui-') as directory:
    os.environ['NVIM_LOG_FILE'] = directory + '/nvim.log'
    os.environ['XDG_STATE_HOME'] = directory + '/state'
    os.environ['XDG_CACHE_HOME'] = directory + '/cache'
    nvim = pynvim.attach('child', argv=['nvim', '--embed', '-u', 'NONE', '-i', 'NONE', '-n'])
    try:
        nvim.ui_attach(100, 32, rgb=True)
        nvim.exec_lua('''
            local root = ...
            vim.opt.rtp:prepend(root)
            vim.opt.rtp:append(root .. '/moonshine.nvim/csv-render')
            vim.opt.rtp:append(root .. '/data/lazy/langmapper.nvim')
            require('configs.langmapper')
            vim.g.csv_notices = {}
            vim.notify = function(message)
                local notices = vim.g.csv_notices
                notices[#notices + 1] = message
                vim.g.csv_notices = notices
            end
            require('configs.csv')
            require('mappings.csv')
            vim.cmd('filetype on')
            vim.o.hidden = true
            vim.wo.wrap = true
            vim.wo.number = true
        ''', str(root))

        def press(keys):
            nvim.input(keys)

        def wait_for(predicate, message):
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if predicate():
                    return
                time.sleep(.02)
            raise AssertionError(message)

        def rendered():
            return nvim.current.buffer[0].startswith('┌')

        def widths():
            return nvim.exec_lua('''
                local widths = {}
                for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
                    widths[#widths + 1] = vim.fn.strdisplaywidth(line)
                end
                return widths
            ''')

        def screen_rows():
            nvim.command('redraw!')
            return nvim.exec_lua('''
                local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
                local lines = {}
                for row = info.winrow, info.winrow + 5 do
                    local line = ''
                    for col = info.wincol, info.wincol + info.width - 1 do
                        line = line .. vim.fn.screenstring(row, col)
                    end
                    lines[#lines + 1] = line
                end
                return lines
            ''')

        source = nvim.current.buffer.number
        lines = ['id,description,unicode', '1,"some text long ' + 'word ' * 25 + '",Ж中文😀', '2,"literal │ inside",last']
        nvim.current.buffer[:] = lines
        nvim.current.buffer.options['filetype'] = 'csv'
        source_column = len(lines[2].split('last')[0].encode('utf-8'))
        nvim.current.window.cursor = (3, source_column)
        press('<A-i>')
        wait_for(rendered, 'real <A-i> did not render a preview')
        assert nvim.current.buffer.options['filetype'] == 'csv-preview'
        assert not nvim.current.buffer.options['modifiable']
        assert not nvim.current.window.options['wrap']
        row, column = nvim.current.window.cursor
        assert nvim.current.buffer[row - 1].encode('utf-8')[column:].startswith(b'last')
        assert len(set(widths())) == 1 and widths()[0] <= 100
        nvim.command('redraw!')
        screen = nvim.exec_lua('''
            local result = {}
            for row = 1, 25 do
                local line = ''
                for col = 1, 100 do line = line .. vim.fn.screenstring(row, col) end
                result[#result + 1] = line
            end
            return table.concat(result, '\\n')
        ''')
        assert '┌' in screen and '│' in screen and 'Ж' in screen, screen
        nvim.ui_try_resize(70, 32)
        wait_for(lambda: rendered() and max(widths()) <= 70, 'resize did not reflow cells')
        assert len(set(widths())) == 1
        press('q')
        wait_for(lambda: nvim.current.buffer.number == source, 'q did not restore the source')
        assert nvim.current.window.options['wrap']
        assert nvim.current.window.options['number']
        assert list(nvim.current.buffer[:]) == lines
        assert nvim.current.window.cursor == (3, source_column)

        # Wide tables keep every column on one horizontal grid.
        wide = [','.join(f'column {i}' for i in range(1, 65))] + [','.join(f'value {i}' for i in range(1, 65))] * 50
        nvim.current.buffer[:] = wide
        press('<A-i>')
        wait_for(rendered, 'wide preview did not render')
        assert min(widths()) > 70
        assert not nvim.current.window.options['wrap']
        press('gg0')
        press('j' * 55)
        wait_for(lambda: nvim.current.window.cursor[0] >= 55, 'repeated j movement failed')
        assert 'column 1' in '\n'.join(screen_rows()), (nvim.funcs.winsaveview(), screen_rows())
        press('kkkk')
        assert 'column 1' in '\n'.join(screen_rows())
        press('50Gzt')
        wait_for(lambda: 'column 1' in '\n'.join(screen_rows()), 'header disappeared on vertical scroll')
        assert nvim.funcs.winsaveview()['topline'] > 3
        assert screen_rows()[0].startswith('┌'), screen_rows()
        press('40zl')
        wait_for(lambda: nvim.funcs.winsaveview()['leftcol'] > 0, 'horizontal scrolling failed')
        assert 'column 5' in '\n'.join(screen_rows()), screen_rows()
        assert nvim.funcs.winsaveview()['topfill'] == 3
        press('gg0zt')
        wait_for(lambda: nvim.funcs.winsaveview()['topline'] == 1, 'scroll to top failed')
        assert nvim.funcs.winsaveview()['topfill'] == 0
        press('<A-i>')
        wait_for(lambda: nvim.current.buffer.number == source, 'wide preview did not close')
        assert list(nvim.current.buffer[:]) == wide
        assert nvim.current.window.options['wrap']

        # Wrapped/multiline headers pin all their rendered fragments.
        nvim.current.buffer[:] = ['id,"First heading', 'Second heading",tail'] + ['1,data,end'] * 50
        press('<A-i>')
        wait_for(rendered, 'multiline-header preview did not render')
        press('50Gzt')
        wait_for(lambda: 'First heading' in '\n'.join(screen_rows()), 'first header fragment missing')
        assert 'Second heading' in '\n'.join(screen_rows()), screen_rows()
        assert nvim.funcs.winsaveview()['topfill'] == 4
        left = nvim.current.window.handle
        nvim.command('split')
        press('70Gzt')
        wait_for(lambda: nvim.funcs.winsaveview()['topline'] >= 65 and nvim.funcs.winsaveview()['topfill'] == 4,
                 'split header did not follow its viewport')
        assert 'First heading' in '\n'.join(screen_rows())
        nvim.api.set_current_win(left)
        assert nvim.funcs.winsaveview()['topline'] < 65
        assert 'First heading' in '\n'.join(screen_rows()), 'split scrolling moved the other header'
        nvim.command('close')
        press('q')
        wait_for(lambda: nvim.current.buffer.number == source, 'pinned preview did not close')

        # Long headings stop at five text lines; moving against the bottom
        # edge must reserve all seven pinned rows (including borders).
        nvim.current.buffer[:] = [','.join(['heading' * 60, '中文' * 150, 'tail'])] + ['1,data,end'] * 100
        nvim.options['scrolloff'] = 8
        press('<A-i>')
        wait_for(rendered, 'long-header preview did not render')
        press('gg0')
        for step in range(60):
            press('j')
            wait_for(lambda: nvim.current.window.cursor[0] == step + 2, 'individual j movement failed')
            rows = screen_rows()
            assert rows[0].startswith('┌') and '...' in rows[5], (step, nvim.funcs.winsaveview(), rows)
        assert nvim.funcs.winsaveview()['topfill'] == 7
        press('kkkk')
        assert '...' in screen_rows()[5]
        press('q')
        wait_for(lambda: nvim.current.buffer.number == source, 'long-header preview did not close')
        nvim.options['scrolloff'] = 0

        # TSV receives the same mapping and keeps quoted tabs inside cells.
        nvim.current.buffer[:] = ['a\tb', '1\t"two\twords"']
        nvim.current.buffer.options['filetype'] = 'tsv'
        press('<A-i>')
        wait_for(rendered, 'TSV mapping failed')
        assert 'two    words' in '\n'.join(nvim.current.buffer[:])
        press('<Esc>')
        wait_for(lambda: nvim.current.buffer.number == source, 'Escape did not close TSV preview')
        print('PASS: real <A-i>, Unicode, resize, pinned multiline headers, independent splits, horizontal scrolling, q/Escape, CSV/TSV and source preservation')
    finally:
        try:
            nvim.command('qa!')
        except (EOFError, pynvim.api.common.NvimError):
            pass
