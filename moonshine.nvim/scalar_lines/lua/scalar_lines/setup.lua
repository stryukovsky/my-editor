vim.api.nvim_create_user_command("ScalarLinesCancel", function()
  require("scalar_lines").cancel()
end, { desc = "Cancel scalar lines selection" })

vim.api.nvim_create_autocmd("BufWipeout", {
  callback = function(event)
    require("scalar_lines").cancel(event.buf)
  end,
})
