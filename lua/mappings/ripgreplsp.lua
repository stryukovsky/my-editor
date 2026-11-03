local map = require "mappings.map"
local ripgreplsp = require "moonshine.ripgreplsp"

map("n", "<leader>fu", function()
  ripgreplsp.find_usages()
end, { desc = "Find usages (ast-grep / ripgrep)" })

map("n", "<leader>fr", function()
  ripgreplsp.find_usages()
end, { desc = "Find references (=usages) (ast-grep / ripgrep)" })

map("n", "<leader>fd", function()
  ripgreplsp.find_definition()
end, { desc = "Find definition (ast-grep / ripgrep)" })
