local map = require "mappings.map"

map("n", "<leader>gH", function()
  vim.cmd "nohlsearch"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  vim.cmd "CodeDiff history"
end, { desc = "Git history" })
