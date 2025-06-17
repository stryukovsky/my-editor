require("lsp_signature").setup {
  floating_window_off_y = -1,
  handler_opts = {
    border = "rounded",
  },
  hint_enable = false,
}

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    vim.diagnostic.config { virtual_lines = false }
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    vim.diagnostic.config { virtual_lines = vim.g.enabled_virtual_lines }
  end,
})
