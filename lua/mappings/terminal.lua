local map = require "mappings.map"
map("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
map("t", "<A-a>", "<C-\\><C-n><C-w>h", { noremap = true, silent = true })
map("t", "<A-s>", "<C-\\><C-n><C-w>j", { noremap = true, silent = true })
map("t", "<A-w>", "<C-\\><C-n><C-w>k", { noremap = true, silent = true })
map("t", "<A-d>", "<C-\\><C-n><C-w>l", { noremap = true, silent = true })
