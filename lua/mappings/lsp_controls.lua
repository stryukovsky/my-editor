local map = require "mappings.map"

map("n", "<leader>lsp", function()
  require("configs.lsp_controls").picker(vim.api.nvim_get_current_buf())
end, { desc = "LSP actions" })
