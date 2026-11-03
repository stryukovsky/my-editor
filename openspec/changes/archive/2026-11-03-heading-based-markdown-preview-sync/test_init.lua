vim.o.columns = 120
vim.o.lines = 40
vim.o.swapfile = false
local base = '/home/dmitry/.config/nvim/data/'
for _, name in ipairs({'nvim-treesitter', 'mini.icons', 'plenary.nvim', 'render-markdown.nvim'}) do
    vim.opt.rtp:prepend(base .. 'lazy/' .. name)
end
vim.opt.rtp:prepend('/home/dmitry/.local/share/nvim/site')
vim.opt.rtp:prepend(base .. 'site')
vim.opt.rtp:prepend(base .. 'treesitter')
vim.cmd.runtime('plugin/plenary.vim')
vim.cmd.runtime('plugin/render-markdown.lua')
vim.api.nvim_create_autocmd('FileType', {pattern='markdown', callback=function(args) vim.treesitter.start(args.buf) end})
vim.o.columns = 80
vim.o.laststatus = 0
vim.o.ruler = false
vim.o.tabstop = 4
vim.o.wrap = false
