local map = require "mappings.map"

map("n", "q", "<Nop>", { desc = "Macro: bare recording disabled" })
map("n", "<leader>q", function()
  return vim.fn.reg_recording() == "" and "qq" or "q"
end, { expr = true, desc = "Macro: toggle recording @q" })
map("n", "Q", "@q", { desc = "Macro: play @q" })
