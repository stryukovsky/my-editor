vim.o.columns = 120
vim.o.lines = 40
vim.o.swapfile = false
local config = vim.env.NVIM_CONFIG_ROOT or vim.fn.expand('~/.config/nvim')
for _, path in ipairs({ '/data/tree-sitter', '/data/lazy/nvim-treesitter/runtime',
    '/data/lazy/plenary.nvim', '/data/lazy/render-markdown.nvim' }) do
    vim.opt.rtp:prepend(config .. path)
end
vim.cmd.runtime('plugin/plenary.vim')
vim.cmd.runtime('plugin/render-markdown.lua')
vim.api.nvim_create_autocmd('FileType', {
    pattern = 'markdown', callback = function(args) vim.treesitter.start(args.buf) end,
})
vim.o.columns = 80
vim.o.laststatus = 0
vim.o.ruler = false
vim.o.tabstop = 4
vim.o.wrap = false
