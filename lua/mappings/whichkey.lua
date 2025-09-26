local map = require "mappings.map"
local wk = require "which-key"
map("n", "<leader>", function()
  wk.show {
    delay = 0,
    mode = "n",
    defer = false,
    waited = 0,
    keys = "<leader>",
  }
end, { nowait = true })
