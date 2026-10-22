-- Statusline branch for Neovim's cwd. Lualine's builtin follows the open file.

local git = require "configs.gitutils"

local M = {}

local NO_GIT = {}

---@type table<string, string|table>
local git_dirs = {}
local branch_name = ""
local branch_cwd ---@type string|nil
local watcher_head ---@type string|nil
local watcher = vim.uv.new_fs_event()

---@param path string
---@return string|nil
local function read_line(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local line = file:read "*l"
  file:close()
  if not line then
    return nil
  end
  return (line:gsub("^%s+", ""):gsub("%s+$", ""))
end

---@param cwd string
---@return string|nil
local function git_dir_for(cwd)
  local cached = git_dirs[cwd]
  if cached == NO_GIT then
    return nil
  end
  if type(cached) == "string" then
    return cached
  end
  local out = git.run({ "rev-parse", "--absolute-git-dir" }, cwd)
  if not out or vim.trim(out) == "" then
    git_dirs[cwd] = NO_GIT
    return nil
  end
  local dir = vim.fs.normalize(vim.trim(out))
  git_dirs[cwd] = dir
  return dir
end

---Branch name, or a short hash when HEAD is detached.
---@param head string
---@param cwd string
---@return string|nil
local function branch_from_head(head, cwd)
  local line = read_line(head)
  if line then
    local name = line:match "^ref: refs/heads/(.+)$"
    if name and name ~= "" then
      return name
    end
    if #line >= 7 and line:match "^%x+$" then
      return line:sub(1, 7)
    end
  end
  local name = git.run({ "symbolic-ref", "--short", "HEAD" }, cwd)
  if name and vim.trim(name) ~= "" then
    return vim.trim(name)
  end
  local hash = git.run({ "rev-parse", "--short=7", "HEAD" }, cwd)
  if hash and vim.trim(hash) ~= "" then
    return vim.trim(hash)
  end
  return nil
end

local arm

local function refresh_lualine()
  if package.loaded.lualine then
    require("lualine").refresh()
  end
end

---@param head string|nil
arm = function(head)
  if watcher_head == head then
    return
  end
  if watcher then
    pcall(function()
      watcher:stop()
    end)
  end
  watcher_head = nil
  if not head or not watcher then
    return
  end
  local stat = vim.uv.fs_stat(head)
  if not stat or stat.type ~= "file" then
    return
  end
  local ok = pcall(function()
    watcher:start(
      head,
      {},
      vim.schedule_wrap(function(err)
        if err then
          return
        end
        local current = watcher_head
        if branch_cwd and current then
          local name = branch_from_head(current, branch_cwd)
          if name then
            branch_name = name
          end
        end
        watcher_head = nil
        if current then
          arm(current)
        end
        refresh_lualine()
      end)
    )
  end)
  if ok then
    watcher_head = head
  end
end

---@return string
function M.branch()
  local cwd = vim.fn.getcwd()
  if cwd == branch_cwd then
    return branch_name
  end
  local dir = git_dir_for(cwd)
  if not dir then
    branch_cwd = cwd
    branch_name = ""
    arm(nil)
    return ""
  end
  local head = dir .. "/HEAD"
  local name = branch_from_head(head, cwd) or ""
  branch_cwd = cwd
  branch_name = name
  arm(head)
  return name
end

function M.lualine_component()
  return {
    function()
      local name = M.branch()
      if name == "" then
        return " "
      end
      return (name:gsub("%%", "%%%%"))
    end,
    icon = "",
  }
end

-- Resolve before the first statusline draw so the branch is already there.
M.branch()

local group = vim.api.nvim_create_augroup("LualineCwdBranch", { clear = true })

-- Drop the cached name so the next draw re-reads HEAD for the current cwd.
local function invalidate()
  branch_cwd = nil
  refresh_lualine()
end

vim.api.nvim_create_autocmd({ "DirChanged", "FocusGained" }, {
  group = group,
  callback = invalidate,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    if watcher then
      watcher:stop()
      watcher:close()
      watcher = nil
    end
  end,
})

return M
