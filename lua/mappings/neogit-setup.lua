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

map("n", "<leader>gL", function()
  local log_path = neogit.get_log_file_path()
  if vim.fn.filereadable(log_path) == 1 then
    vim.cmd.edit(log_path)
  else
    vim.notify("Log file does not exist: " .. log_path, vim.log.levels.WARN)
  end
end, { desc = "git show neogit logs" })

map("n", "<leader>gx", "<cmd>GitConflictListQf<cr>", { desc = "git: conflicts" })
