local map = require "mappings.map"
map("n", "<leader>gd", function()
  vim.cmd "nohlsearch"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  if vim.g.diffViewOpened or vim.g.fileHistoryOpened then
    vim.notify "Already opened Diffview. Close it before"
    return
  end

  vim.fn.feedkeys(":DiffviewOpen ", "n")
end, { desc = "Git comp...are" })

map("n", "<leader>gq", function()
  vim.cmd "DiffviewClose"
  vim.g.diffViewOpened = false
  vim.g.fileHistoryOpened = false
end, { desc = "Git diff close" })

map("n", "<leader>gs", function()
  vim.cmd "nohlsearch"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  if vim.g.diffViewOpened or vim.g.fileHistoryOpened then
    vim.notify "Already opened Diffview. Close it before"
    return
  end

  vim.cmd "DiffviewOpen"
end, { desc = "Git status" })
