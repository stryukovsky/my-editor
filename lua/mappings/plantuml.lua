local map = require "mappings.map"

map("n", "<leader>puu", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  require("configs.plantuml").visualize(lines)
end, { desc = "PlantUML visualize current buffer" })

map("n", "<leader>pui", function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  require("configs.plantuml").render_png(lines)
end, { desc = "PlantUML render PNG and open" })