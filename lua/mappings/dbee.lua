local map = require "mappings.map"
local create_connection = require "configs.dbee"

map("n", "<leader>dbp", function()
  create_connection "postgres"
end, {desc = "DB: postgres"})
