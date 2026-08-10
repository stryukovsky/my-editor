local map = require "mappings.map"
local bigfiles = require "configs.bigfiles"

map("n", "<leader>big", function()
  bigfiles.toggle()
end, { desc = "Toggle heavy buffer features" })
