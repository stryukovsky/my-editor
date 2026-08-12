local map = require "mappings.map"

map("n", "<leader>todo", function()
  local todo = "TODO: "
  local line_count = vim.api.nvim_buf_line_count(0)
  require("Comment.api").insert.linewise.above()

  if vim.api.nvim_buf_line_count(0) == line_count then
    return
  end

  local row, column = unpack(vim.api.nvim_win_get_cursor(0))
  local insertion_column = column + 1

  vim.api.nvim_buf_set_text(0, row - 1, insertion_column, row - 1, insertion_column, { todo })
  vim.api.nvim_win_set_cursor(0, { row, insertion_column + #todo - 1 })
end, { desc = "Insert TODO comment above" })
