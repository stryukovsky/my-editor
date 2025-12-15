return function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("filetype", { buf = buf }) == "TelescopePrompt" then
      vim.api.nvim_win_close(win, true)
      return true
    end
  end
  return false
end
