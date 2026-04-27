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
  neogit.action("log", "log_current", { kind = "split", "--graph", "--decorate", "--topo-order", "--max-count=256" })()
end, { desc = "git: current brach log" })

map("n", "<leader>gL", function()
  neogit.action("log", "log_other", { kind = "split", "--graph", "--decorate", "--topo-order", "--max-count=256" })()
end, { desc = "git: select branch and log it" })

map("n", "<leader>gg", function()
  neogit.open {}
end, { desc = "git: status" })

-- Periodic git fetch controls
map("n", "<leader>gpf", function()
  require("configs.periodic-git-fetch").start()
end, { desc = "git: start periodic fetch" })

map("n", "<leader>gpt", function()
  require("configs.periodic-git-fetch").stop()
end, { desc = "git: stop periodic fetch" })

map("n", "<leader>gpm", function()
  local pgf = require("configs.periodic-git-fetch")
  if pgf.timer and pgf.timer:is_active() then
    vim.notify("Periodic fetch active, next in " .. (pgf.get_current_backoff_interval() / 1000) .. "s (backoff index: " .. pgf.current_backoff_index .. ")", vim.log.levels.INFO)
  else
    vim.notify("Periodic fetch not active", vim.log.levels.INFO)
  end
end, { desc = "git: show periodic fetch status" })

map("n", "<leader>gx", "<cmd>GitConflictListQf<cr>", { desc = "git: conflicts" })
