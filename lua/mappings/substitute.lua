local map = require "mappings.map"
-- local substitute = require "substitute"
local range = require "substitute.range"

map("x", "<leader>r", function()
  range.visual {
    -- prompt_current_text = true,
    range = "%",
  }
end, { noremap = true })

map("x", "<leader>R", function()
  range.word {
    -- prompt_current_text = true,
    subject = function(_)
      return ""
    end,
  }
end, { noremap = true })
