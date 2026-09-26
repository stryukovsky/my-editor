return function()
  vim.cmd "noh"
  vim.snippet.stop()
  require("configs.slashing").forget()
end
