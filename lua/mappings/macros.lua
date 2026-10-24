local map = require "mappings.map"

map("n", "q", "<Nop>", { desc = "Disable bare macro recording" })
map("n", "<leader>q", function()
  return vim.fn.reg_recording() == "" and "qq" or "q"
end, { expr = true, desc = "Start / stop recording macro q" })
map("n", "Q", "@q", { desc = "Play macro q" })
map("n", "<leader>sl", "<cmd>sleep 500m<cr>", { desc = "Sleep 0.5 seconds" })
