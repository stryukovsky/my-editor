local map = require "mappings.map"
local ripgrelsp = require "configs.ripgrelsp"

map("n", "<leader>rd", function()
  ripgrelsp.find_definition()
end, { desc = "rg: find definition" })

map("n", "<leader>ru", function()
  ripgrelsp.find_usages()
end, { desc = "rg: find usages" })

map("n", "<leader>ad", function()
  ripgrelsp.find_definition_ast()
end, { desc = "ast-grep: find definition" })

map("n", "<leader>au", function()
  ripgrelsp.find_usages_ast()
end, { desc = "ast-grep: find usages" })
