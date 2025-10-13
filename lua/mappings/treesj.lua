local map = require "mappings.map"
local treesj = require "treesj"
map("n", "<leader>ss", function()
  treesj.toggle()
end, { desc = "SJ: Toggle split/join" })
