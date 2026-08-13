local map = require "mappings.map"
local md_table_viewer = require "configs.md_table_viewer"

map("n", "<A-i>", function()
  if vim.bo.filetype == "markdown" then
    md_table_viewer.view_row()
  else
    vim.diagnostic.open_float()
  end
end, { desc = "Markdown: view table row / show diagnostic" })
