local map = require "mappings.map"
local grapple = require "grapple"

map("n", "<leader>mm", function()
  grapple.toggle()
  vim.print "Toggled current buffer"
end, { desc = "Tag a file" })

map("n", "<leader>M", function()
  grapple.toggle()
  vim.print "Toggled current buffer"
end, { desc = "Tag a file" })
