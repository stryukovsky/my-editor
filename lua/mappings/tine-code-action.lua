-- code actions view
local map = require "mappings.map"

map({ "n", "v" }, "<leader>ca", function()
  vim.lsp.buf.code_action {}
end, { noremap = true, silent = true, desc = "Actions: LSP Code action" })
