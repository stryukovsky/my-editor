local neogit = require "neogit"
local map = require "mappings.map"

map("n", "<leader>gc", function()
  neogit.open { "commit", kind = "split" }
end, { desc = "git: commit" })

map("n", "<leader>gPush", function()
  neogit.open { "push" }
end, { desc = "git: push" })

map("n", "<leader>gmerge", function()
  neogit.open { "merge" }
end, { desc = "git: merge" })

map("n", "<leader>gMerge", function()
  neogit.open { "merge" }
end, { desc = "git: merge" })

map("n", "<leader>gpush", function()
  neogit.open { "push" }
end, { desc = "git: push" })

map("n", "<leader>gFetch", function()
  neogit.open { "fetch" }
end, { desc = "git: fetch" })

map("n", "<leader>gfetch", function()
  neogit.open { "fetch" }
end, { desc = "git: fetch" })

map("n", "<leader>gpull", function()
  neogit.open { "pull" }
end, { desc = "git: pull" })

map("n", "<leader>gPull", function()
  neogit.open { "pull" }
end, { desc = "git: pull" })

map("n", "<leader>gb", function()
  neogit.open { "branch" }
end, { desc = "git: branch" })

map("n", "<leader>gl", function()
  -- neogit.open { "log",  }
  neogit.action("log", "log_all_branches", { kind = "split" })()
end, { desc = "git: log" })

map("n", "<leader>gg", function()
  neogit.open {}
end, { desc = "git: status" })

map("n", "<leader>gx", "<cmd>GitConflictListQf<cr>", { desc = "git: conflicts" })
