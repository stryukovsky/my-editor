local git = require "configs.gitutils"
local M = {}

-- Timer reference for stopping later
M.timer = nil

-- Backoff intervals in milliseconds (5s, 15s, 30s, 1m, 2m, 5m, 10m, 30m)
M.backoff_intervals =
  { 5000, 15000, 30000, 60000, 120000, 300000, 600000, 1800000 }
M.current_backoff_index = 1

-- Default interval (10 minutes) in milliseconds
M.default_interval = 600000

-- Store last successful fetch timestamp
M.last_fetch_timestamp = nil

-- Commits the local branch is ahead of (↑) or behind (↓) its upstream.
-- Refreshed asynchronously; the statusline and the code-window heading read this table.
M.sync_state = {
  ahead = nil,
  behind = nil,
  cwd = nil,
  at = 0,
  pending = false,
}
M.sync_ttl = 2

local log = require("plenary.log").new {
  plugin = "periodic-git-fetch",
  level = "debug", -- trace, debug, info, warn, error, fatal
}
local function log_print_debug(msg)
  log.debug(msg)
end

-- Check if we're in a git repository.
function M.is_git_repo()
  return git.root() ~= nil
end

-- Git records unfinished operations and lock files in its per-worktree directory.
function M.is_git_operation_in_progress()
  local cwd = vim.fn.getcwd()
  local commands = package.loaded["configs.git_commands"]
  local root = git.root(cwd)
  if not root or (commands and commands.busy[root]) or M.fetch_pending then
    return true
  end
  local gitdir = git.run({ "rev-parse", "--absolute-git-dir" }, cwd)
  if not gitdir then
    return true
  end
  gitdir = vim.trim(gitdir)
  for _, name in ipairs {
    "rebase-merge",
    "rebase-apply",
    "MERGE_HEAD",
    "CHERRY_PICK_HEAD",
    "REVERT_HEAD",
    "sequencer",
    "BISECT_LOG",
    "index.lock",
    "HEAD.lock",
  } do
    if vim.uv.fs_stat(gitdir .. "/" .. name) then
      return true
    end
  end
  return false
end

function M.git_fetch(callback)
  if M.is_git_operation_in_progress() then
    log_print_debug "Git operation in progress, skipping fetch"
    if callback then
      callback(false)
    end
    return
  end
  local cwd = vim.fn.getcwd()
  M.fetch_pending = true
  git.job {
    args = { "fetch" },
    cwd = cwd,
    on_exit = function(code, stderr)
      vim.schedule(function()
        M.fetch_pending = false
        if code == 0 then
          M.last_fetch_timestamp = os.time()
          M.refresh_sync_state(cwd, true)
        else
          log_print_debug("Git fetch failed: " .. stderr)
        end
        if callback then
          callback(code == 0)
        end
      end)
    end,
  }
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
    if not M.timer or M.timer:is_closing() then
      return
    end
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
    log_print_debug "Periodic git fetch already running"
    return
  end

  -- Create new timer
  M.timer = vim.uv.new_timer()

  -- Perform initial fetch on startup
  M.git_fetch(function(success)
    if not M.timer or M.timer:is_closing() then
      return
    end
    if success then
      M.reset_backoff()
      -- Schedule next fetch at default interval
      M.timer:start(M.default_interval, 0, vim.schedule_wrap(M.on_timer))
    else
      -- If initial fetch fails, start with backoff
      M.advance_backoff()
      local interval = M.get_current_backoff_interval()
      M.timer:start(interval, 0, vim.schedule_wrap(M.on_timer))
      log_print_debug "Periodic git fetch started with backoff due to initial failure"
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
    log_print_debug "Periodic git fetch stopped"
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

  vim.api.nvim_create_autocmd(
    { "WinEnter", "BufWinEnter", "DirChanged", "VimResized" },
    {
      group = vim.api.nvim_create_augroup(
        "PeriodicGitFetchBehindBanner",
        { clear = true }
      ),
      callback = function()
        if vim.v.event and vim.v.event.scope then
          M.refresh_sync_state(vim.fn.getcwd(), true)
        end
        M.apply_behind_banner()
      end,
    }
  )
end

local function format_ago(timestamp)
  local diff = os.time() - timestamp
  local minutes = math.floor(diff / 60)
  local hours = math.floor(minutes / 60)
  if minutes == 0 then
    return "now"
  elseif hours > 0 then
    return hours .. "h ago"
  else
    return minutes .. "m ago"
  end
end

-- left = commits only on HEAD (local is ahead), right = commits only on upstream.
function M.refresh_sync_state(cwd, force)
  local state = M.sync_state
  if state.pending then
    return
  end
  local now = os.time()
  if not force and state.cwd == cwd and (now - state.at) < M.sync_ttl then
    return
  end
  state.pending = true
  vim.system(
    { "git", "rev-list", "--left-right", "--count", "HEAD...@{upstream}" },
    { cwd = cwd, text = true },
    function(obj)
      vim.schedule(function()
        state.pending = false
        if vim.fn.getcwd() ~= cwd then
          state.at = 0
          M.apply_behind_banner()
          return
        end
        state.cwd = cwd
        state.at = os.time()
        local ahead, behind = nil, nil
        if obj.code == 0 and obj.stdout then
          ahead, behind = obj.stdout:match "(%d+)%s+(%d+)"
          ahead, behind = tonumber(ahead), tonumber(behind)
        end
        state.ahead = ahead
        state.behind = behind
        M.apply_behind_banner()
        if package.loaded["lualine"] then
          require("lualine").refresh()
        end
      end)
    end
  )
end

-- Static winbar text. A `%!` expression is painted into the statusline on redraw.
local function is_our_banner(bar)
  return bar:find("^%%#GitRemoteBehind#", 1) ~= nil
end

local skip_banner_ft = {
  dashboard = true,
  alpha = true,
  oil = true,
  ["neo-tree"] = true,
  trouble = true,
  lazy = true,
  mason = true,
  TelescopePrompt = true,
}

local function ensure_behind_hl()
  vim.api.nvim_set_hl(
    0,
    "GitRemoteBehind",
    { fg = "#ffffff", bg = "#ff1744", bold = true }
  )
end

-- Commits on the upstream that are not in HEAD. Nil when unknown or zero.
function M.behind_count()
  local state = M.sync_state
  if state.cwd ~= vim.fn.getcwd() then
    return nil
  end
  local behind = state.behind
  if not behind or behind < 1 then
    return nil
  end
  return behind
end

---@param win? integer
function M.winbar(win)
  local behind = M.behind_count()
  if not behind then
    return ""
  end
  local noun = behind == 1 and "COMMIT" or "COMMITS"
  local label = " REMOTE HAS " .. behind .. " " .. noun .. " "
  win = win or vim.g.statusline_winid
  local width = 0
  if win and vim.api.nvim_win_is_valid(win) then
    width = vim.api.nvim_win_get_width(win)
  end
  if width <= #label then
    return "%#GitRemoteBehind#" .. label
  end
  local pad = math.floor((width - #label) / 2)
  return "%#GitRemoteBehind#"
    .. string.rep(" ", pad)
    .. label
    .. string.rep(" ", width - pad - #label)
end

local function is_code_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  if vim.bo[buf].buftype ~= "" or skip_banner_ft[vim.bo[buf].filetype] then
    return false
  end
  local bar = vim.wo[win].winbar
  return bar == "" or is_our_banner(bar)
end

-- Full-width white-on-red heading on ordinary code windows while behind > 0.
function M.apply_behind_banner()
  ensure_behind_hl()
  local show = M.behind_count() ~= nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_code_window(win) then
      local bar = vim.wo[win].winbar
      if show then
        local text = M.winbar(win)
        if bar ~= text then
          vim.wo[win].winbar = text
        end
      elseif is_our_banner(bar) then
        vim.wo[win].winbar = ""
      end
    end
  end
end

function M.lualine_component()
  return function(self)
    if not self.behind_hl then
      self.behind_hl =
        self:create_hl({ fg = "#ff4d6a", gui = "bold" }, "behind")
    end

    local cwd = vim.fn.getcwd()
    M.refresh_sync_state(cwd, false)

    local parts = {}
    local ahead, behind = M.sync_state.ahead, M.sync_state.behind
    if M.sync_state.cwd == cwd then
      if ahead and ahead > 0 then
        parts[#parts + 1] = ahead .. " ↑"
      end
      if behind and behind > 0 then
        parts[#parts + 1] = self:format_hl(self.behind_hl)
          .. behind
          .. " ↓"
          .. self:get_default_hl()
      end
    end

    local last_fetch = M.last_fetch_timestamp
    if last_fetch then
      parts[#parts + 1] = "fetched " .. format_ago(last_fetch)
    end

    if #parts == 0 then
      return ""
    end
    return "  " .. table.concat(parts, " ")
  end
end

return M
