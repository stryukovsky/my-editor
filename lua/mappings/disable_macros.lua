local map = require "mappings.map"
local opts = { noremap = true, silent = true }
map("n", "q:", "<nop>", opts)
map("n", "qq", "<nop>", opts)
vim.keymap.set("n", "q", "<Nop>", { noremap = true })
