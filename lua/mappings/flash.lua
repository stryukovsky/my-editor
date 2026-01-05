local flash = require "flash"
local map = require "mappings.map"

map("n", "f", function()
  flash.jump()
end, { desc = "Flash to symbol" })

map("n", "F", function()
  flash.treesitter()
end, { desc = "Flash to syntax element (Treesitter)" })
