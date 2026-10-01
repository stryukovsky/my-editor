vim.g.rainbow_delimiters = {
  condition = function(bufnr)
    if vim.api.nvim_buf_line_count(bufnr) >= 5000 then
      return false
    end
    local ok, bigfiles = pcall(require, "configs.bigfiles")
    if ok and bigfiles.is_skipping(bufnr) then
      return false
    end
    return true
  end,
}
