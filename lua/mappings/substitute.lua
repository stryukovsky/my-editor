local map = require "mappings.map"
local range = require "substitute.range"

map("x", "<leader>rr", function()
  range.visual {
    -- prompt_current_text = true,
    range = "%",
  }
end, { noremap = true })

map("x", "<leader>ri", function()
  vim.api.nvim_feedkeys(":s///g", "ni", false)
end, { noremap = true })
