vim.g.rainbow_delimiters = {
  condition = function(bufnr)
    return vim.api.nvim_buf_line_count(bufnr) < 5000
  end,
}
