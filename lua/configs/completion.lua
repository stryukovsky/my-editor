-- LSP drives its own asynchronous completion; other buffers use native sources.
vim.o.autocomplete = true
vim.o.autocompletedelay = 100
vim.o.pumborder = "rounded"
vim.o.pumblend = 0
vim.o.pumheight = 10
vim.o.pummaxwidth = 70
-- Empty completion results are routine while typing, not command-line errors.
vim.opt.shortmess:append "cC"
vim.opt.completeopt =
  { "menu", "menuone", "noselect", "fuzzy", "nosort", "popup" }
vim.opt.complete = { ".", "w", "b" }
vim.o.completefunc = "v:lua.NativeExtraComplete"
vim.opt.wildoptions = { "pum", "fuzzy" }
vim.opt.wildmode = { "longest:full", "full" }

return require "native_completion.integration"
