local aidviser = require("plugin_name")
local map = require("mappings.map")

map("n", "<leader>ad", aidviser.send_request, {desc = "aidviser analyze buffer"})

