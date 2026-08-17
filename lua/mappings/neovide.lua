local map = require "mappings.map"

if not vim.g.neovide then
  return
end

-- Neovide forwards Command as <D-…>; it does not paste like a terminal.
local function paste()
  vim.api.nvim_paste(vim.fn.getreg "+", true, -1)
end

map({ "n", "i", "v", "c", "t" }, "<D-v>", paste, { silent = true, desc = "Neovide paste" })
map("v", "<D-c>", '"+y', { silent = true, desc = "Neovide copy" })
