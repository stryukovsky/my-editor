local map = require("mappings.map")
local oil = require("oil")

map("n", "<A-o>", oil.toggle_float, { desc = "oil toggle float browser"})
