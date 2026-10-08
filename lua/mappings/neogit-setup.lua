local async = require "plenary.async"
local neogit = require "neogit"
local map = require "mappings.map"
local notify = require "configs.notify"
local open_neogit_status = require "utils.open_neogit_status"
local ui_prevent_mess = require "utils.ui_prevent_mess"

local function open_neogit(args)
  ui_prevent_mess()
  neogit.open(args)
end

local function run_neogit_action(group, action, args)
  ui_prevent_mess()
  neogit.action(group, action, args)()
end

map("n", "<leader>gc", function()
  open_neogit { "commit", kind = "split" }
end, { desc = "git: commit" })

map("n", "<leader>gC", function()
  async.run(function()
    local git = require "neogit.lib.git"
    if not git.status.is_dirty() then
      async.util.scheduler()
      notify.send("Git", "Nothing to checkpoint", vim.log.levels.WARN)
      return
    end

    local staged = git.cli.add.all.call { hidden = true }
    if not staged:success() then
      async.util.scheduler()
      local err = staged.stderr and table.concat(staged.stderr, "\n") or ""
      notify.send("Git", err ~= "" and err or "Failed to stage changes", vim.log.levels.ERROR)
      return
    end

    local branch = git.branch.current() or "HEAD"
    local msg = ("chore(%s): checkpoint %s"):format(branch, os.date "%H:%M")
    local result = git.cli.commit.message(msg).call { hidden = true }
    async.util.scheduler()
    if result:success() then
      notify.send("Git", msg)
      neogit.dispatch_refresh()
      open_neogit_status()
    else
      local err = result.stderr and table.concat(result.stderr, "\n") or ""
      notify.send("Git", err ~= "" and err or "Checkpoint commit failed", vim.log.levels.ERROR)
    end
  end)
end, { desc = "git: commit checkpoint" })

map("n", "<leader>gPush", function()
  open_neogit { "push" }
end, { desc = "git: push" })

map("n", "<leader>gmerge", function()
  open_neogit { "merge" }
end, { desc = "git: merge" })

map("n", "<leader>gMerge", function()
  open_neogit { "merge" }
end, { desc = "git: merge" })

map("n", "<leader>gpush", function()
  open_neogit { "push" }
end, { desc = "git: push" })

map("n", "<leader>gFetch", function()
  open_neogit { "fetch" }
end, { desc = "git: fetch" })

map("n", "<leader>gfetch", function()
  open_neogit { "fetch" }
end, { desc = "git: fetch" })

map("n", "<leader>gpull", function()
  open_neogit { "pull" }
end, { desc = "git: pull" })

map("n", "<leader>gd", function()
  open_neogit { "diff" }
end, { desc = "git: diff" })

map("n", "<leader>gPull", function()
  open_neogit { "pull" }
end, { desc = "git: pull" })

map("n", "<leader>gb", function()
  open_neogit { "branch" }
end, { desc = "git: branch" })

map("n", "<leader>gl", function()
  run_neogit_action("log", "log_current", { kind = "split", "--graph", "--decorate", "--topo-order", "--max-count=256" })
end, { desc = "git: current brach log" })

map("n", "<leader>gL", function()
  run_neogit_action("log", "log_other", { kind = "split", "--graph", "--decorate", "--topo-order", "--max-count=256" })
end, { desc = "git: select branch and log it" })

map("n", "<A-k>", function()
  open_neogit_status()
end, { desc = "git: status" })

map("n", "<leader>gg", function()
  open_neogit_status()
end, { desc = "git: status" })

-- Periodic git fetch controls
map("n", "<leader>gpf", function()
  require("configs.periodic-git-fetch").start()
end, { desc = "git: start periodic fetch" })

map("n", "<leader>gpt", function()
  require("configs.periodic-git-fetch").stop()
end, { desc = "git: stop periodic fetch" })

map("n", "<leader>gpm", function()
  local pgf = require "configs.periodic-git-fetch"
  if pgf.timer and pgf.timer:is_active() then
    vim.notify(
      "Periodic fetch active, next in " .. (pgf.get_current_backoff_interval() / 1000) .. "s (backoff index: " .. pgf.current_backoff_index .. ")",
      vim.log.levels.INFO
    )
  else
    vim.notify("Periodic fetch not active", vim.log.levels.INFO)
  end
end, { desc = "git: show periodic fetch status" })

map("n", "<leader>gx", "<cmd>GitConflictListQf<cr>", { desc = "git: conflicts" })
