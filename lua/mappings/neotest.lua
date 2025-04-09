local map = require "mappings.map"
local neotest = require("neotest")

map("n", "<leader>tt", function ()
  neotest.run.run()
end, {desc = "Test run nearest"})

map("n", "<leader>tT", function ()
  neotest.run.run(vim.fn.expand("%"))
end, {desc = "Test run file"})

