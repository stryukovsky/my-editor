local unset = vim.keymap.del

unset("i", "<Tab>")
unset("s", "<Tab>")
unset("i", "<S-Tab>")
unset("s", "<S-Tab>")

local map = require "mappings.map"
map("n", "<Esc>", function()
  vim.cmd "noh"
  vim.snippet.stop()
end, { desc = "general clear highlights" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })
map("n", "qq", function() end)
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
require "mappings.lspconfig"
require "mappings.dap"
require "mappings.ui-components"
require "mappings.search"
require "mappings.gitsigns"
require "mappings.multicursor"
require "mappings.navigation"
require "mappings.ui-components"
require "mappings.substitute"
require "mappings.text-case"
require "mappings.neogit-setup"
require "mappings.snippet"
require "mappings.logviewer"
require "mappings.grapple"
require "mappings.treesj"
require "mappings.disable_macros"
require "mappings.yanky"
require "mappings.flash"
