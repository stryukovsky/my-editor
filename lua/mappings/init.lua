-- require "nvchad.mappings"
-- require "nvchad.configs.lspconfig"
local unset = vim.keymap.del

-- unset nvchad shortcuts
-- unset({ "n" }, "<leader>h")
-- unset({ "n" }, "<leader>v")
-- unset({ "n" }, "<C-s>")
-- unset({ "n" }, "<leader>x")
-- unset({ "n" }, "<A-v>")
-- unset({ "n" }, "<C-w>")
-- unset({ "n" }, "<leader>wK")
-- unset({ "n" }, "<leader>wk")
-- unset({ "n", "v" }, "<leader>/")
-- unset({ "n", "t" }, "<A-h>")
-- unset("i", "<C-h>")
-- unset("i", "<C-j>")
-- unset("i", "<C-k>")
-- unset("i", "<C-l>")
-- unset("i", "<C-b>")
-- unset("n", "<leader>ch")
-- unset("n", "<leader>n")
-- unset("n", "<leader>rn")
local map = require "mappings.map"
map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

require "mappings.lspconfig"
require "mappings.dap"
require "mappings.ui-components"
require "mappings.search"
require "mappings.gitsigns"
require "mappings.multicursor"
require "mappings.nvimcmp"
require "mappings.tabufline"
require "mappings.tine-code-action"
require "mappings.ui-components"
require "mappings.substitute"
require "mappings.markdownpreview"
require "mappings.neotest"
require "mappings.dbee"
require "mappings.text-case"
require "mappings.harpoon-setup"
require "mappings.refactoring-setup"
require "mappings.neogit-setup"
