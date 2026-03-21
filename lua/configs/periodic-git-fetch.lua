local async = require "plenary.async"
local M = {}

-- Timer reference for stopping later
M.timer = nil

-- Backoff intervals in milliseconds (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m)
M.backoff_intervals = { 5000, 15000, 30000, 60000, 120000, 300000, 600000, 1800000 }
M.current_backoff_index = 1

-- Default interval (10 minutes) in milliseconds
M.default_interval = 600000

local function notify_user(msg)
  vim.notify(msg, vim.log.levels.INFO)
end

-- Check if we're in a git repository
function M.is_git_repo()
  local result = vim.fn.system "git rev-parse --is-inside-work-tree 2>/dev/null"
  return vim.v.shell_error == 0 and result:match "true" ~= nil
end

-- Check if any git operations are in progress using NeoGit's state
function M.is_git_operation_in_progress()
  if not M.is_git_repo() then
    return true -- Not a git repo, don't fetch
  end

  -- Try to get NeoGit's repository state
  local success, git = pcall(require, "neogit.lib.git")
  if not success then
    return true -- Can't access NeoGit, be safe
  end

  -- Check for rebase in progress
  if git.repo.state.rebase.head ~= nil then
    return true
  end

  -- Check for merge in progress
  if git.repo.state.merge.head ~= nil then
    return true
  end

  -- Check for cherry-pick or revert in progress
  if git.repo.state.sequencer.head ~= nil then
    return true
  end

  -- Check for bisect in progress
  if git.repo.state.bisect.finished == false and #git.repo.state.bisect.items > 0 then
    return true
  end

  return false
end

-- Perform git fetch using NeoGit's fetch functionality
function M.git_fetch(callback)
  async.run(function()
    if M.is_git_operation_in_progress() then
      notify_user "Git operation in progress, skipping fetch"
      return false
    end

    -- Use NeoGit's fetch functionality
    local success, git = pcall(require, "neogit.lib.git")
    if not success then
      notify_user "Failed to load NeoGit library, skipping fetch"
      return false
    end

    -- Perform the fetch using NeoGit's fetch function
    local result = git.cli.fetch.args("", "").call { ignore_error = true, long = true, hidden = true }
    if result and result:success() then
      notify_user "Git fetch completed successfully"
      return true
    else
      local error_msg = result and result.stderr and table.concat(result.stderr, "\n") or "Unknown error"
      notify_user("Git fetch failed: " .. error_msg)
      return false
    end
  end, callback)
end

-- Get current backoff interval
function M.get_current_backoff_interval()
  return M.backoff_intervals[M.current_backoff_index]
end

-- Advance to next backoff interval (up to max)
function M.advance_backoff()
  if M.current_backoff_index < #M.backoff_intervals then
    M.current_backoff_index = M.current_backoff_index + 1
  end
end

-- Reset backoff to initial state
function M.reset_backoff()
  M.current_backoff_index = 1
end

-- Timer callback function
function M.on_timer()
  M.git_fetch(function(success)
    if success then
      -- Reset backoff on success
      M.reset_backoff()
      -- Schedule next fetch at default interval
      M.timer:stop()
      M.timer:start(M.default_interval, 0, vim.schedule_wrap(M.on_timer))
    else
      -- Advance backoff on failure
      M.advance_backoff()
      -- Schedule next attempt at backoff interval
      local interval = M.get_current_backoff_interval()
      M.timer:stop()
      M.timer:start(interval, 0, vim.schedule_wrap(M.on_timer))
    end
  end)
end

-- Start periodic git fetch
function M.start()
  -- Don't start if already running
  if M.timer and M.timer:is_active() then
    notify_user "Periodic git fetch already running"
    return
  end

  -- Create new timer
  M.timer = vim.uv.new_timer()

  -- Perform initial fetch on startup
  M.git_fetch(function(success)
    if success then
      M.reset_backoff()
      -- Schedule next fetch at default interval
      M.timer:start(M.default_interval, 0, vim.schedule_wrap(M.on_timer))
    else
      -- If initial fetch fails, start with backoff
      M.advance_backoff()
      local interval = M.get_current_backoff_interval()
      M.timer:start(interval, 0, vim.schedule_wrap(M.on_timer))
      notify_user "Periodic git fetch started with backoff due to initial failure"
    end
  end)
end

-- Stop periodic git fetch
function M.stop()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
    M.reset_backoff()
    notify_user "Periodic git fetch stopped"
  end
end

-- Setup function to be called from init.lua
function M.setup()
  -- Start the periodic fetch when Neovim is fully loaded
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      -- Give some time for everything to initialize
      vim.defer_fn(function()
        M.start()
      end, 5000) -- Start after 5 seconds
    end,
  })

  -- Stop the timer when Neovim exits
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      M.stop()
    end,
  })
end

return M
