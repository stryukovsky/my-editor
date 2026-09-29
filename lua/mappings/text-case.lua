local map = require "mappings.map"
map("n", "<leader>ta", function()
  require("utils.ui_prevent_mess")()
  vim.cmd "TextCaseOpenTelescope"
end, { desc = "Actions: text convert case" })
