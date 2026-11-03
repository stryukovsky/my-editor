"""uv run --with pynvim python tests/markdown_mermaid_ui.py [config-root]."""
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

import pynvim

config = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.home() / '.config/nvim'
with tempfile.TemporaryDirectory(prefix='nvim-mermaid-') as directory:
    os.environ['XDG_STATE_HOME'] = directory + '/state'
    os.environ['XDG_CACHE_HOME'] = directory + '/cache'
    os.environ['XDG_RUNTIME_DIR'] = directory
    os.environ['NVIM_LOG_FILE'] = directory + '/nvim.log'
    diagram = 'graph LR\nA[Source] --> B[Preview]'
    changed = 'graph LR\nA[Updated] --> B[Preview]'
    def ascii_output(source):
        return subprocess.run([str(config / 'bin/mermaid-ascii'), '-f', '-'], input=source + '\n',
                              text=True, capture_output=True, check=True, env={**os.environ, 'NO_COLOR': '1'}).stdout.rstrip('\n').split('\n')
    expected = ascii_output(diagram)
    source_lines = ['# Title', '', 'Preview this document.', '', '| A | B |', '| --- | --- |', '| x | y |', '',
                    '```mermaid', *diagram.split('\n'), '```', '', '## After', '', r'$\alpha \cdot x$']
    file = Path(directory) / 'diagram.md'
    original = '\n'.join(source_lines) + '\n'
    file.write_text(original)
    nvim = pynvim.attach('child', argv=['nvim', '--embed', '-u', 'NONE', '-i', 'NONE', '-n'])
    nvim.ui_attach(120, 45, rgb=True)
    try:
        nvim.exec_lua('''
            local config = ...
            vim.opt.rtp:append(vim.fn.glob(config .. "/moonshine.nvim/*", true, true))
            for _, path in ipairs({ '/data/tree-sitter', '/data/lazy/nvim-treesitter/runtime',
                '/data/lazy/render-markdown.nvim', '/data/lazy/langmapper.nvim', '/data/lazy/plenary.nvim',
                '/data/lazy/nvim-web-devicons', '/data/lazy/nvim-notify', '' }) do
                vim.opt.rtp:prepend(config .. path)
            end
            vim.g.mapleader = ' '
            require 'configs.langmapper'
            require 'configs.render-markdown'
            require('render-markdown.core.manager').init()
            require 'mappings.inspection'
            require 'mappings.visualize'
            vim.g.mermaid_notices = {}
            vim.notify = function(message)
                local messages = vim.g.mermaid_notices
                messages[#messages + 1] = message
                vim.g.mermaid_notices = messages
            end
            vim.api.nvim_create_autocmd('FileType', { pattern = 'markdown', callback = function(a) vim.treesitter.start(a.buf) end })
            vim.cmd('filetype on')
            vim.opt.number = false
            vim.opt.signcolumn = 'no'
            vim.opt.foldcolumn = '0'
            vim.opt.swapfile = false
        ''', str(config))
        nvim.command('edit ' + str(file))
        nvim.exec_lua("vim.treesitter.start(0, 'markdown')")
        src = nvim.current.buffer.number
        undo = nvim.funcs.undotree()
        modified = nvim.current.buffer.options['modified']

        def wait_for(predicate, label):
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                if predicate():
                    return
                time.sleep(.02)
            raise AssertionError(label + ': ' + str(nvim.exec_lua('return vim.g.mermaid_notices')))

        def press(keys):
            nvim.input(keys)
            # An RPC round trip gives the input loop an opportunity to dispatch.
            nvim.eval('1')

        def contains(lines, block):
            return any(lines[i:i+len(block)] == block for i in range(len(lines)))

        for row in (3, 7, 10):
            nvim.current.window.cursor = (row, 0)
            press('<A-i>')
            wait_for(lambda: nvim.current.buffer.number != src, 'preview did not open')
            dst = nvim.current.buffer.number
            wait_for(lambda: contains(list(nvim.current.buffer[:]), expected), 'real diagram did not render')
            lines = list(nvim.current.buffer[:])
            assert not any('graph LR' in line for line in lines), lines
            assert any('┌' in line and '┬' in line for line in lines), 'table missing'
            assert not nvim.current.window.options['wrap'], 'diagram can soft-wrap'
            assert not nvim.current.buffer.options['modifiable']
            time.sleep(.35)
            nvim.command('redraw!')
            screen = nvim.exec_lua('''
                local lines = {}
                for row = 1, 42 do
                    local line = ''
                    for col = 1, 120 do line = line .. vim.fn.screenstring(row, col) end
                    lines[#lines + 1] = line
                end
                return table.concat(lines, '\\n')
            ''')
            assert 'Source' in screen and 'Preview' in screen, screen
            assert 'α' in screen and '⋅' in screen, screen
            press('<A-i>')
            wait_for(lambda: nvim.current.buffer.number == src, 'preview did not close')
            assert list(nvim.current.buffer[:]) == source_lines
            assert nvim.current.buffer.options['modified'] == modified
            assert nvim.funcs.undotree() == undo
            assert not nvim.exec_lua("return require('render-markdown.state').get(...).enabled", src)

        press('<A-i>')
        wait_for(lambda: nvim.current.buffer.number != src, 'preview reopen failed')
        dst = nvim.current.buffer.number
        wait_for(lambda: contains(list(nvim.current.buffer[:]), expected), 'reopen conversion failed')
        nvim.exec_lua('''
            local src = ...
            vim.api.nvim_buf_set_lines(src, 10, 11, false, { 'A[Updated] --> B[Preview]' })
            vim.api.nvim_exec_autocmds('TextChanged', { buffer = src })
        ''', src)
        updated = ascii_output(changed)
        wait_for(lambda: contains(list(nvim.current.buffer[:]), updated), 'changed source did not refresh')
        nvim.current.window.cursor = (len(nvim.current.buffer) - 2, 0)
        press('<A-i>')
        wait_for(lambda: nvim.current.buffer.number == src, 'updated preview close failed')
        assert nvim.current.window.cursor[0] >= 14, nvim.current.window.cursor
        assert file.read_text() == original, 'saved source was changed'

        # Reopening retries a missing converter and preserves its entire fence.
        nvim.exec_lua("require('render-markdown.core.preview').mermaid.command = '/no/such/mermaid-ascii'")
        press('<A-i>')
        wait_for(lambda: nvim.current.buffer.number != src, 'fallback preview failed')
        wait_for(lambda: bool(nvim.exec_lua('return vim.g.mermaid_notices')), 'missing converter warning absent')
        assert contains(list(nvim.current.buffer[:]), ['```mermaid', *changed.split('\n'), '```'])
        press('<A-i>')
        wait_for(lambda: nvim.current.buffer.number == src, 'fallback close failed')

        # Dispatch tests use real mapped input and replace only action endpoints.
        nvim.exec_lua('''
            vim.g.inspect_calls = { csv = 0, markdown = 0, diagnostic = 0 }
            local function count(kind)
                local calls = vim.g.inspect_calls; calls[kind] = calls[kind] + 1; vim.g.inspect_calls = calls
            end
            require('integrations.csv_table_viewer').view_row = function() count('csv') end
            require('moonshine.markdown.table').view_row = function() count('markdown') end
            vim.diagnostic.open_float = function() count('diagnostic') end
        ''')
        press(' mdi')
        wait_for(lambda: nvim.vars['inspect_calls']['markdown'] == 1, 'Markdown inspector shortcut failed')
        for ft in ('csv', 'tsv', 'lua'):
            nvim.current.buffer.options['filetype'] = ft
            press('<A-i>')
        wait_for(lambda: nvim.vars['inspect_calls'] == {'csv': 2, 'markdown': 1, 'diagnostic': 1}, 'non-Markdown dispatch changed')

        nvim.command('enew')
        nvim.command('file standalone.mmd')
        nvim.current.buffer[:] = diagram.split('\n')
        press(' va')
        wait_for(lambda: nvim.current.buffer.options['filetype'] == 'mermaid-preview', 'standalone Mermaid visualization failed')
        assert contains(list(nvim.current.buffer[:]), expected)
        print('PASS: real <A-i> UI, diagram geometry, tables/math, source state, refresh, fallback, inspection dispatch, standalone Mermaid')
    finally:
        try:
            nvim.command('qa!')
        except (EOFError, pynvim.api.common.NvimError):
            pass
