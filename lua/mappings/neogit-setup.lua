local neogit = require "neogit"
local map = require "mappings.map"

map("n", "<leader>gc", function ()
  neogit.open({ "commit", kind = "float"})
end, {desc = "git: commit"})

map("n", "<leader>gPush", function ()
  neogit.open({ "push", kind = "float"})
end, {desc = "git: log"})
