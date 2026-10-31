local logviewer = require "configs.logviewer"
local map = require "mappings.map"

map("n", "<leader>logd", function()
  logviewer("DEBUG", false)
end, { desc = "Log: remove DEBUG entries" })
