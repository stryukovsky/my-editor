require "nvchad.mappings"

local unset = vim.keymap.del

-- unset nvchad shortcuts
unset({ "n" }, "<leader>h")
unset({ "n" }, "<leader>v")
unset({ "n" }, "<C-s>")
unset({ "n" }, "<C-w>")

require "mappings.dap"
require "mappings.ui-components"
require "mappings.search"
require "mappings.gitsigns"
require "mappings.multicursor"
require "mappings.nvimcmp"
require "mappings.tabufline"
require "mappings.tine-code-action"
require "mappings.ui-components"
