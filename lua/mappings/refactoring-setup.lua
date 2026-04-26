local map = require "mappings.map"

local refactoring = require "refactoring"
map({ "n", "x" }, "<leader>Re", function()
  return refactoring.extract_func()
end, { expr = true, desc = "Extract Function" })

map({ "n", "x" }, "<leader>RI", function()
  return refactoring.inline_func()
end, { expr = true, desc = "Inline Function" })

map({ "n", "x" }, "<leader>Ri", function()
  return refactoring.inline_var()
end, { expr = true, desc = "Inline Variable" })

map({ "n", "x" }, "<leader>Rv", function()
  return refactoring.extract_var()
end, { expr = true, desc = "Extract Variable" })

map({ "n", "x" }, "<leader>Rf", function()
  return refactoring.extract_func_to_file()
end, { expr = true, desc = "Extract Function To File" })
