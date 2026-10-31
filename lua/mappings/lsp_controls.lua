local map = require "mappings.map"

map("n", "<leader>lsp", function()
  require("lsp-riced").picker(vim.api.nvim_get_current_buf())
end, { desc = "LSP actions" })
