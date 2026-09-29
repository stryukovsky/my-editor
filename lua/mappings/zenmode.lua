local map = require "mappings.map"

map("n", "<leader>zen", function()
  require("configs.zenmode").toggle_ui()
end, { desc = "Toggle zen mode" })
