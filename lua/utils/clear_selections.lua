return function()
  vim.cmd "noh"
  vim.snippet.stop()
  require("moonshine.slashing").forget()
end
