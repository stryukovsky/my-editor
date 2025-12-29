local map = require "mappings.map"
local treesj = require "treesj"
map("n", "<leader>ss", function()
  treesj.split { recursive = true }
end, { desc = "SJ: split" })

map("n", "<leader>sj", function()
  treesj.join()
end, { desc = "SJ: join" })
