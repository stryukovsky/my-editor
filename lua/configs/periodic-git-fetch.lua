local M = {}

-- Timer reference for stopping later
M.timer = nil

-- Backoff intervals in milliseconds (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m)
M.backoff_intervals = { 5000, 15000, 30000, 60000, 120000, 300000, 600000, 1800000 }
M.current_backoff_index = 1

-- Default interval (10 minutes) in milliseconds
M.default_interval = 600000

-- Check if we're in a git repository
function M.is_git_repo()
  local result = vim.fn.system "git rev-parse --is-inside-work-tree 2>/dev/null"
  return vim.v.shell_error == 0 and result:match "true" ~= nil
end

-- Get git working directory
function M.get_git_dir()
  local result = vim.fn.system "git rev-parse --git-dir 2>/dev/null"
  if vim.v.shell_error == 0 then
    -- Remove trailing newlines and whitespace
    return result:gsub("[\r\n]+$", "")
  end
  return nil
end

-- Check if internet is available
function M.is_internet_available()
  -- Simple check by pinging a reliable server
  local result = vim.fn.system "ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1 && echo 'online' || echo 'offline'"
  return result:match "online" ~= nil
end

-- Check if git remote is accessible (more reliable than generic ping)
function M.is_git_remote_accessible()
  if not M.is_git_repo() then
    return false
  end

  -- Try to fetch just one ref to test connectivity
  local result = vim.fn.system "git ls-remote --heads 2>/dev/null | head -1"
  return vim.v.shell_error == 0 and #result > 0
end

-- Check if any git operations are in progress
function M.is_git_operation_in_progress()
  if not M.is_git_repo() then
    return true -- Not a git repo, don't fetch
  end

  local git_dir = M.get_git_dir()
  if not git_dir then
    return true -- Couldn't determine git dir
  end

  -- Make sure git_dir doesn't have trailing newline
  git_dir = git_dir:gsub("[\r\n]+$", "")

  -- Check for rebase in progress
  local rebase_merge = vim.fn.system("test -d '" .. git_dir .. "/rebase-merge' && echo 'in_progress' || echo 'not_in_progress'")
  local rebase_apply = vim.fn.system("test -d '" .. git_dir .. "/rebase-apply' && echo 'in_progress' || echo 'not_in_progress'")
  if rebase_merge:match "^in_progress" or rebase_apply:match "^in_progress" then
    return true
  end

  -- Check for merge in progress
  local merge_result = vim.fn.system("test -f '" .. git_dir .. "/MERGE_HEAD' && echo 'in_progress' || echo 'not_in_progress'")
  if merge_result:match "^in_progress" then
    return true
  end

  -- Check for cherry-pick in progress
  local cherry_result = vim.fn.system("test -f '" .. git_dir .. "/CHERRY_PICK_HEAD' && echo 'in_progress' || echo 'not_in_progress'")
  if cherry_result:match "^in_progress" then
    return true
  end

  -- Check for revert in progress
  local revert_result = vim.fn.system("test -f '" .. git_dir .. "/REVERT_HEAD' && echo 'in_progress' || echo 'not_in_progress'")
  if revert_result:match "^in_progress" then
    return true
  end

  -- Check for bisect in progress
  local bisect_result = vim.fn.system("test -f '" .. git_dir .. "/BISECT_LOG' && echo 'in_progress' || echo 'not_in_progress'")
  if bisect_result:match "^in_progress" then
    return true
  end

  return false
end

-- Perform git fetch
function M.git_fetch()
  if M.is_git_operation_in_progress() then
    print "Git operation in progress, skipping fetch"
    return false
  end

  -- Check internet connectivity
  if not M.is_internet_available() then
    print "No internet connection, skipping fetch"
    return false
  end

  -- Perform the fetch (only fetch from default remote to be more efficient)
  local result = vim.fn.system "git fetch 2>&1"
  if vim.v.shell_error == 0 then
    print "Git fetch completed successfully"
    return true
  else
    print("Git fetch failed: " .. result)
    return false
  end
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
  local success = M.git_fetch()

  if success then
    -- Reset backoff on success
    M.reset_backoff()
    -- Schedule next fetch at default interval
    M.timer:set(M.default_interval, 0, vim.schedule_wrap(M.on_timer))
  else
    -- Advance backoff on failure
    M.advance_backoff()
    -- Schedule next attempt at backoff interval
    local interval = M.get_current_backoff_interval()
    M.timer:set(interval, 0, vim.schedule_wrap(M.on_timer))
  end
end

-- Start periodic git fetch
function M.start()
  -- Don't start if already running
  if M.timer and M.timer:is_active() then
    print "Periodic git fetch already running"
    return
  end

  -- Create new timer
  M.timer = vim.loop.new_timer()

  -- Perform initial fetch on startup
  local success = M.git_fetch()

  if success then
    M.reset_backoff()
    -- Schedule next fetch at default interval
    M.timer:start(M.default_interval, 0, vim.schedule_wrap(M.on_timer))
    print "Periodic git fetch started successfully"
  else
    -- If initial fetch fails, start with backoff
    M.advance_backoff()
    local interval = M.get_current_backoff_interval()
    M.timer:start(interval, 0, vim.schedule_wrap(M.on_timer))
    print "Periodic git fetch started with backoff due to initial failure"
  end
end

-- Stop periodic git fetch
function M.stop()
  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
    M.reset_backoff()
    print "Periodic git fetch stopped"
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

