local map = require "mappings.map"
local md_table_viewer = require "configs.md_table_viewer"

map("n", "<A-i>", function()
  md_table_viewer.view_row()
end, { desc = "Markdown: view table row" })
