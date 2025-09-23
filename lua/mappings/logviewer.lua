local logviewer = require "configs.logviewer"
local map = require "mappings.map"

map("n", "<leader>logD", function()
  logviewer("DEBUG", false)
end, { desc = "Log: remove DEBUG entries" })
