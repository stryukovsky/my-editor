local map = require "mappings.map"

map("n", "<leader>zen", function()
  require("zen-mode").toggle()
end, { desc = "Toggle zen mode" })
