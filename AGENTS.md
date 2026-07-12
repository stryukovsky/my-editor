# Neovim Config

Personal Neovim configuration managed by [lazy.nvim](https://github.com/folke/lazy.nvim).

## Entrypoint & Loading Order

- `init.lua` bootstraps lazy.nvim, then requires: `options` → `configs` → `mappings` → `theme`
- `lua/configs/init.lua` orchestrates ~50 plugin setup modules — add new plugin configs here
- `lua/mappings/init.lua` loads all keymap modules — add new bindings here
- Plugin specs live in `lua/plugins/` (core.lua, mason.lua, ai.lua, misc.lua, web.lua)

## Keymap Convention (Critical)

**All keymaps must use `local map = require "mappings.map"`** — this wraps `langmapper.map` for RU/EN keyboard layout awareness. Do NOT use `vim.keymap.set` directly.

Usage: `map("n", "<leader>f", function() ..., { desc = "..." })`

## Path & Data Quirks

- `vim.fn.stdpath("data")` is monkey-patched to resolve to `~/.config/nvim/data/` (not the default `~/.local/share/nvim`)
- Mason binaries are added to PATH via `vim.env.PATH = stdpath("data") .. "/mason/bin"`
- State/cache/treesitter dirs are under `~/.config/nvim/data/`

## Theme

- Auto-switches based on hour: dark (`material-deep-ocean`) at 20:00–07:00, light (`material-lighter`) otherwise
- Theme config: `lua/configs/material-theme.lua`
- Highlight overrides in `lua/highlight.lua` — runs on `ColorScheme` and `UIEnter` autocmds; add new overrides inside `override_highlights()`

## Folding

- `foldmethod=expr`, `foldexpr=v:lua.vim.treesitter.foldexpr()` (set per-buffer via FileType autocmd)
- `foldlevel=9900` (folds start open)
- Fold fillchars: `foldopen=""`, `foldclose=""`, `foldsep=" "`
- `foldcolumn="1"`
- `statuscol.nvim` renders the fold/sign/line-number column — config in `lua/configs/statuscolumn.lua`
- `Folded` highlight override in `lua/highlight.lua:103`

## Language & Input

- `vim.opt.langmap` remaps Russian → English keystrokes (affects both Normal and command-line modes)
- `spelllang=programming,en,ru` with `spelloptions=camel,noplainbuffer`
- Spell checked on BufWinEnter for files <10000 lines and <10KB
- Large files (>10000 lines or >10KB) skip treesitter folding/indent and spell

## Code Formatting (`conform.nvim`)

| Language    | Formatter |
|-------------|-----------|
| Lua         | stylua    |
| CSS/HTML/JS/JSON | prettier |
| TypeScript   | prettier  |
| Go          | gofumpt   |
| Rust        | rustfmt   |
| Python      | black     |
| Scala       | scalafmt  |
| XML         | xmlformatter |
| Solidity    | prettier + prettier-plugin-solidity |

StyLua config: `.stylua.toml` (150 cols, 2-space indent, double quotes, no parens).

## LSP & DAP

- LSP servers enabled in `lua/configs/lspconfig.lua`: html, cssls, ts_ls, lua_ls, sqls, bashls, basedpyright, gopls, clangd, solidity_ls, texlab, jdtls, move_analyzer
- DAP configs in `lua/configs/debuggers.lua`: pwa-node (JS/TS), jdtls (Java), dap-python, dap-go, rustaceanvim (Rust), nvim-metals (Scala)
- Mason handles LSP/DAP/linter binary installs

## Notable Plugins

- **Completion**: blink.cmp (with minuet-ai.nvim inline completion)
- **Git**: neogit (fork at stryukovsky/neogit, `log-view-fix-open-commit-link` branch), gitsigns, git-conflict.nvim (stryukovsky fork)
- **AI**: codecompanion.nvim, minuet-ai.nvim, aidviser.nvim (stryukovsky)
- **File tree**: neo-tree.nvim, oil.nvim
- **Statusline**: lualine.nvim (theme sets `lualine_style = "stealth"`)
- **Search**: telescope.nvim + fzf-native, flash.nvim, spectre.nvim
- **Misc**: yanky.nvim, marks.nvim, nvim-surround, nvim-gomove, treesj, Comment.nvim, todo-comments.nvim, refactoring.nvim, render-markdown.nvim (for md + Avante), rainbow-delimiters.nvim (stryukovsky fork), grapple.nvim, trouble.nvim

## Other Conventions

- `CursorLineNr` bg synced to lualine mode color dynamically (see `lua/highlight.lua`)
- `Cursor` reversed + bold per-mode with custom blink timing
- No node/perl/ruby/python providers loaded by default (`g:loaded_*_provider = 0`)
- Clipboard: gpaste-client preferred, falls back to unnamedplus
- DAP breakpoint signs use Nerd Font icons
- Rust filetype has custom keymaps in `after/ftplugin/rust.lua` (H for hover actions, `<leader>dd` for debuggables)
- No tests — this is a config repository

## Lazy-lock

Pin updates via `lazy-lock.json`. Do not edit manually.