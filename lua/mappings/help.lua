local map = require "mappings.map"

local function toggle()
  require("configs.mappings_help").toggle()
end

local opts = { desc = "Show mappings help", silent = true, nowait = true }
map("n", "?", toggle, opts)

-- this mapping breaks <A-,> on mac os
-- map("n", "<A-?>", toggle, opts)
map("n", "<A-S-/>", toggle, opts)
