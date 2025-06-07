-- code actions view
local map = require "mappings.map"

map({ "n", "v" }, "<leader>ca", function()
  require("tiny-code-action").code_action {}
end, { noremap = true, silent = true, desc = "Actions: LSP Code action"})
