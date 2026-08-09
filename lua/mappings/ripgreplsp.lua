local map = require "mappings.map"
local ripgreplsp = require "configs.ripgreplsp"

map("n", "<leader>rd", function()
  ripgreplsp.find_definition()
end, { desc = "rg: find definition" })

map("n", "<leader>ru", function()
  ripgreplsp.find_usages()
end, { desc = "rg: find usages" })
