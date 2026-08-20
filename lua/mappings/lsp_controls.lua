local map = require "mappings.map"

map("n", "<leader>lsp", function()
  require("configs.lsp_controls").picker()
end, { desc = "LSP actions" })
