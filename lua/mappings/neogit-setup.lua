local neogit = require "neogit"
local map = require "mappings.map"

map("n", "<leader>gc", function()
  neogit.open { "commit", kind = "split" }
end, { desc = "git: commit" })

map("n", "<leader>gPush", function()
  neogit.open { "push", kind = "float" }
end, { desc = "git: push" })

map("n", "<leader>gmerge", function()
  neogit.open { "merge", kind = "float" }
end, { desc = "git: merge" })

map("n", "<leader>gMerge", function()
  neogit.open { "merge", kind = "float" }
end, { desc = "git: merge" })

map("n", "<leader>gpush", function()
  neogit.open { "push", kind = "float" }
end, { desc = "git: push" })

map("n", "<leader>gFetch", function()
  neogit.open { "fetch", kind = "float" }
end, { desc = "git: fetch" })

map("n", "<leader>gfetch", function()
  neogit.open { "fetch", kind = "float" }
end, { desc = "git: fetch" })

map("n", "<leader>gpull", function()
  neogit.open { "pull", kind = "float" }
end, { desc = "git: pull" })

map("n", "<leader>gPull", function()
  neogit.open { "pull", kind = "float" }
end, { desc = "git: pull" })

map("n", "<leader>gb", function()
  neogit.open { "branch", kind = "float" }
end, { desc = "git: branch" })

map("n", "<leader>gg", function()
  neogit.open {}
end, { desc = "git: status" })
