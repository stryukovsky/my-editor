local map = require "mappings.map"
local treesj = require "treesj"
map("n", "<leader>sjs", function()
  treesj.split { recursive = true }
end, { desc = "SJ: split" })

map("n", "<leader>sjj", function()
  treesj.join()
end, { desc = "SJ: join" })
