local neogit = require "neogit"
local map = require "mappings.map"

map("n", "<leader>gc", function ()
  neogit.open({ "commit", kind = "float"})
end, {desc = "git: commit"})
