_G.codediff_tabpages = {}
vim.api.nvim_create_autocmd("User", {
  pattern = "CodeDiffOpen",
  callback = function()
    local tabpage = vim.api.nvim_get_current_tabpage()
    _G.codediff_tabpages[tabpage] = true
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "CodeDiffClose",
  callback = function()
    local tabpage = vim.api.nvim_get_current_tabpage()
    _G.codediff_tabpages[tabpage] = nil
  end,
})

return function()
  if not _G.codediff_tabpages then
    return false
  end
  return _G.codediff_tabpages[vim.api.nvim_get_current_tabpage()] == true
end
