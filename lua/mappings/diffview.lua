local map = require "mappings.map"
map("n", "<leader>gd", function()
  vim.cmd "nohlsearch"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  if vim.g.diffViewOpened or vim.g.fileHistoryOpened then
    vim.notify "Already opened Diffview. Close it before"
    return
  end

  vim.fn.feedkeys(":CodeDiff ", "n")
end, { desc = "Git comp...are" })


map("n", "<leader>gH", function()
  vim.cmd "nohlsearch"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)

  vim.cmd "CodeDiff history"
end, { desc = "Git history" })

