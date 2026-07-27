local map = require "mappings.map"

map("n", "<leader>i=", function()
  require("configs.image").increase_scale()
end, { desc = "Image increase scale" })

map("n", "<leader>i-", function()
  require("configs.image").decrease_scale()
end, { desc = "Image decrease scale" })
