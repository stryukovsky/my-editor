# Design

## Context

Inspected 2026-10-31: active config /home/dmitry/.config/nvim, installed Neovim 0.12.6; the chat workspace is a separate older Neovim source checkout. Base decisions on installed runtime help, not that checkout. AGENTS.md describes some older behavior: actual specs disable Blink, completion.lua implements native completion, and lspconfig.lua uses native config/enable. No main OpenSpec specs currently exist.

## Goals / Non-Goals

**Goals:** Identify concrete native substitutions and their costs; implement native line commenting as the conservative first slice after review.

**Non-Goals:** Implement optional table rows, remove all plugins, rewrite custom Git/DAP workflows, or replace external language tools.

## Decisions

### Options grounded in the active config

Native API availability does not imply default enabled behavior. Custom glue is required where stated. Version floors below refer to the named replacement; the proposed implementation baseline is the installed 0.12.6.

| Current plugin / feature | Native option | Fit and feature cost | Recommendation / version |
| --- | --- | --- | --- |
| Comment.nvim | Built-in gc/gcc, gc operator and commentstring | Strong line-comment fit. Preserve Solidity // and shell # overrides. TODO mapping directly calls Comment.api; migrate it. Blockwise gb is not equivalent. | First slice; native comments 0.10+; retain plugin for blockwise until separately resolved |
| vim-illuminate | vim.lsp.buf.document_highlight() and clear_references(), attach-aware autocmds | Good with supporting LSP; loses regex/Tree-sitter fallback in unsupported buffers. Preserve technical-buffer denylist and bigfiles suppression. | Good conditional candidate; available on installed version |
| nvim-hlslens | hlsearch, incsearch, shortmess search-count display, searchcount() | Native count gives position/total, not nearest-match floating lens. slashing.lua explicitly starts/stops hlslens. | Good if floating lens can go; mature native features |
| marks.nvim | m, apostrophe/backtick jumps, :marks, :delmarks, ]'/[' and ]`/[` motions | Native mark management exists; loses automatic signs and exact ]m/[m semantics unless mapped. Preserve dm and leader deletion commands if desired. | Optional simplification; mature native features |
| fidget.nvim | vim.lsp.status() in statusline, LspProgress event | LSP progress is available; no equivalent floating presentation or fidget Telescope history by default. | Good if statusline-only progress is sufficient; status() 0.10+ |
| telescope-ui-select.nvim | Default vim.ui.select | Built-in numbered selection works; loses fuzzy picker presentation. Other Telescope pickers remain. | Easy UI simplification; 0.6+ |
| nvim-notify | Default vim.notify plus :messages | Broad coupling: configs.notify send/replace, history/error scratch buffers, escape dismissal, direct requires. Native notify has no compatible replacement-id/history API. | Medium effort; accept simpler UI and adapt callers |
| LuaSnip + friendly-snippets | vim.snippet.expand/active/jump | Native LSP snippet expansion/navigation already used. No native catalog loader for VS Code/SnipMate/Lua collections or LuaSnip dynamic nodes. Installed loaders alone do not establish active expansion usage. | Audit real catalog usage before removing; vim.snippet 0.10+ |
| nvim-lspconfig | vim.lsp.config/enable with own lsp/*.lua definitions | Setup API already native; plugin still supplies server cmd/root/settings definitions. Deleting it alone breaks servers. Must own definitions including Java bundles and JSON schema settings. | Keep unless willing to maintain server catalog; APIs 0.11+ |
| conform.nvim | vim.lsp.buf.format, formatprg/gq or explicit external jobs | LSP formatting not equivalent to selected black/gofumpt/prettier/scalafmt/forge pipelines; async/range/error handling needs glue. | Keep for current formatter choices |
| nvim-treesitter | vim.treesitter.start/foldexpr | Highlight/fold engine already native. Plugin installs many parsers/queries; removing installer does not supply them. | Keep parser management; native folding already adopted |
| lualine.nvim | statusline option and expressions | Can show filename, mode, diagnostics, LSP progress; must recreate custom debug output, macro and mode-color integration. | Optional, medium effort |
| statuscol.nvim | statuscolumn option (0.9+) | Basic fold/sign/number columns native; current split MiniDiff namespaces, click handlers, DAP actions, virtual-line handling require custom code. | Keep unless simplifying column behavior |
| barbar.nvim + scope.nvim | tabline, :buffers/:buffer/:bnext, native tabpages | Buffer tabs and tab-local buffer membership are separate from native tabpages. Loses current presentation/scope policy. | Optional with workflow change |
| Telescope + fzf-native + undo extension | :find with path/wildmenu/fuzzy completion, :grep/:vimgrep + quickfix, :buffers, :oldfiles, :undolist/earlier/later | Useful individual replacements; custom Git/project/debug pickers, previews, undo browsing and consumers prevent a drop-in removal. :grep may still use external rg. | Keep overall; migrate individual commands only |
| Trouble | Native diagnostics/location lists/quickfix and LSP list results | Basic diagnostics fit, but custom DAP, Git and MiniDiff sources and grouped interactive views are richer. | Keep custom views; native diagnostics lists optional |
| Neo-tree + Oil | Bundled netrw (:Explore/:Lexplore), :edit/:find | Browsing exists; no equivalent editable Oil directory buffer, symbols/buffer trees, custom file controls or cross-process clipboard. Conflicts with existing tree proposals if removed. | Keep |
| todo-comments | :vimgrep /TODO\|FIXME/ + quickfix, :match | Search possible; loses structured keyword styling/navigation/picker integration. TODO insertion is separate. | Optional with visible feature loss |
| nvim-gomove | :move, >/<, visual block edits | Good for simple vertical line moves; horizontal/selection behavior needs mappings and undo checks. | Optional narrow replacement |
| multicursor.nvim | Visual block, macros, :global/:normal, :substitute | Alternatives for repetitive edits, no native interactive multiple cursors. | Keep if multicursor workflow matters |
| grug-far | :grep/:vimgrep + :cdo substitute + :cfdo update | Cross-file replacement possible; preview, filtering, escaping, write scope and error handling differ. | Keep unless adopting command workflow |
| flash.nvim | f/F/t/T, /?, n/N, marks | Native motions/search work; no labeled multi-target jumps. | Preference, not equivalence |
| which-key | :map and existing custom mappings help | Inspection possible; no equivalent timed key-prefix discovery popup. | Keep if popup used |
| dashboard-nvim / zen-mode | Empty startup buffer; :only and local UI options | Simpler startup/focus achievable; loses dashboard actions and managed window restoration unless implemented. | Optional cosmetic simplification |
| lazy.nvim | vim.pack (0.12+) / packages | Built-in installation/update possible; event/ft/cmd loading, builds, dependency ordering, pins and UI need explicit migration. Current lazy-lock.json is empty; preserve actual plugin revisions before any switch. | Defer; broad migration, little benefit for this first slice |
| Mason, DAP/neotest language adapters, treesj, sibling-swap, surround, refactoring, langmapper, render-markdown, rainbow delimiters, CSV viewer, theme/icons, lspeek | Some low-level native APIs or manual commands exist | No comparable built-in end-user feature across current configured behavior. Native langmap does not automatically replace langmapper's wrapped mappings. | Retain; avoid rebuilding plugins in config |

### Already native

configs/completion.lua uses autocomplete/autocompletedelay, fuzzy popup completion, vim.lsp.completion.enable, and command-line completion. Blink and blink.compat are disabled. mappings/snippet.lua uses vim.snippet; options.lua uses native folding. configs/lspconfig.lua already uses config/enable, while require lspconfig still makes server definitions available. No claimed startup/performance gain has been measured.

### First implementation boundary

Use native line-comment operator behavior and buffer-local commentstring overrides. All explicit mappings go through mappings.map. Replace Comment.api usage in mappings/todo.lua with a small commentstring-based insertion that retains position/indentation. Retain Comment.nvim for blockwise commands, disabling only overlapping line mappings so load order cannot restore them. Full plugin removal requires a later explicit blockwise decision. Alternative: keep everything; simpler today but retains overlapping line machinery. Reimplementing block comments now expands scope without evidence of need.

## Risks / Trade-offs

- Mapping interception or RU/EN regression → inspect final effective maps and exercise both layouts.
- Shell/Solidity comment syntax differs → verify all configured filetypes, including env/dotenv.
- Insert position or indentation regression → compare TODO behavior at top of file, blank lines, and indented lines.
- Apparent dependency removal leaves callers → search all requires and mappings before removing any plugin.
- Native API substituted for richer feature → optional table entries require separate scoped changes and explicit behavior choices.

## Migration Plan

Apply only the comment slice after review. Record effective mappings first; change handlers, docs and TODO insertion together. Verify in normal configured Neovim with disposable files, then inspect startup messages. Roll back the comment-related diff to restore previous behavior; leave installed plugins/data intact. No plugin-manager migration, lockfile hand editing, or data deletion.

## Evidence

Primary evidence is installed /usr/share/nvim/runtime/doc/{news,news-0.10,news-0.11,lsp,lua,change,options}.txt and actual lua/plugins, configs and mappings. Online reference: https://neovim.io/doc/user/lsp.html and https://neovim.io/doc/user/lua.html (checked 2026-10-31). Installed help governs this machine where online docs differ.
