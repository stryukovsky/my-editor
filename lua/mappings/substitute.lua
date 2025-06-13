local map = require "mappings.map"

map("x", "<leader>ri", function()
  vim.api.nvim_feedkeys(":s///g", "ni", false)
end, { noremap = true, desc = "Replace in selection" })

map("n", "<leader>rr", function()
  vim.api.nvim_feedkeys(":%s///g", "ni", false)
end, { noremap = true, desc = "Replace in all file" })
