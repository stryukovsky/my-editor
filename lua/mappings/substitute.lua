local map = require "mappings.map"
local range = require "substitute.range"

map("x", "<leader>r", function()
  range.visual {
    -- prompt_current_text = true,
    range = "%",
  }
end, { noremap = true })

map("x", "<leader>R", function()

  vim.api.nvim_feedkeys(":s///", "ni", false)
end, { noremap = true })
