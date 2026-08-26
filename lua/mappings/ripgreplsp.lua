local map = require "mappings.map"
local ripgrelsp = require "configs.ripgrelsp"

map("n", "<leader>fu", function()
  ripgrelsp.find_usages()
end, { desc = "Find usages (ast-grep / ripgrep)" })

map("n", "<leader>fr", function()
  ripgrelsp.find_usages()
end, { desc = "Find references (=usages) (ast-grep / ripgrep)" })

map("n", "<leader>fd", function()
  ripgrelsp.find_definition()
end, { desc = "Find definition (ast-grep / ripgrep)" })
