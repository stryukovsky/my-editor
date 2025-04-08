local map = require "mappings.map"
local substitute = require "substitute"
local range = require "substitute.range"

map("x", "<leader>r", function ()
  range.visual()
end, { noremap = true })

map("x", "<leader>R", function ()
  range.word({range = "<" })
end, { noremap = true })
