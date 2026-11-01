local map = require "mappings.map"

map("n", "q", "<Nop>", { desc = "Macro: bare recording disabled" })
map("n", "<leader>q", function()
  return vim.fn.reg_recording() == "" and "qq" or "q"
end, { expr = true, desc = "Macro: toggle recording @q" })
local replay_key = vim.fn.has "nvim-0.13" == 1 and "<leader>Q" or "Q"
map("n", replay_key, "@q", { desc = "Macro: play @q" })
