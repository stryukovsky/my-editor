local map = require "mappings.map"
map({ "n", "x" }, "<leader>ra", function()
  require("telescope").extensions.refactoring.refactors()
end, { desc = "Actions: refactoring" })

local refactoring = require "refactoring"
map({ "n", "x" }, "<leader>Re", function()
  return refactoring.refactor "Extract Function"
end, { expr = true, desc = "Extract Function" })

map({ "n", "x" }, "<leader>RI", function()
  return refactoring.refactor "Inline Function"
end, { expr = true, desc = "Inline Function" })

map({ "n", "x" }, "<leader>Ri", function()
  return refactoring.refactor "Inline Variable"
end, { expr = true, desc = "Inline Variable" })

map({ "n", "x" }, "<leader>Rbb", function()
  return refactoring.refactor "Extract Block"
end, { expr = true, desc = "Extract Block" })

map({ "n", "x" }, "<leader>Rbf", function()
  return refactoring.refactor "Extract Block To File"
end, { expr = true, desc = "Extract Block To File" })

map({ "n", "x" }, "<leader>Rv", function()
  return refactoring.refactor "Extract Variable"
end, { expr = true, desc = "Extract Variable" })

map({ "n", "x" }, "<leader>Rf", function()
  return refactoring.refactor "Extract Function To File"
end, { expr = true, desc = "Extract Function To File" })
