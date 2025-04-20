local map = require "mappings.map"
local create_connection = require "configs.dbee"

map("n", "<leader>Dp", function()
  create_connection "postgres"
end)
