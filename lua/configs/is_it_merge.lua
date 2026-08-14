local M = {}

local INTERVAL_MS = 3000

vim.g.is_it_merge = ""

local git_dir ---@type string|nil
local start_key ---@type string|nil
local timer ---@type uv.uv_timer_t|nil

local function file_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_line(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local line = f:read "*l"
  f:close()
  if not line then
    return nil
  end
  return (line:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function start_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and vim.fn.filereadable(name) == 1 then
    return vim.fn.fnamemodify(name, ":p:h")
  end
  return vim.fn.getcwd()
end

---Walk up from a path and return the absolute git dir (handles worktrees).
local function find_git_dir(dir)
  local current = dir
  while current and current ~= "" do
    local git_path = current .. "/.git"
    local stat = vim.uv.fs_stat(git_path)
    if stat then
      if stat.type == "directory" then
        return git_path
      end
      if stat.type == "file" then
        local line = read_line(git_path)
        if line then
          local gitdir = line:match "^gitdir:%s*(.+)$"
          if gitdir then
            if gitdir:sub(1, 1) ~= "/" then
              gitdir = vim.fn.fnamemodify(current .. "/" .. gitdir, ":p")
            end
            return gitdir:gsub("/$", "")
          end
        end
      end
    end
    local parent = vim.fn.fnamemodify(current, ":h")
    if parent == current then
      break
    end
    current = parent
  end
end

local function rebase_label(dir)
  local merge_dir = dir .. "/rebase-merge"
  if file_exists(merge_dir) then
    local msgnum = read_line(merge_dir .. "/msgnum")
    local last = read_line(merge_dir .. "/end")
    if msgnum and last then
      return "REBASE " .. msgnum .. "/" .. last
    end
    return "REBASE"
  end
  local apply_dir = dir .. "/rebase-apply"
  if file_exists(apply_dir) and file_exists(apply_dir .. "/rebasing") then
    local next_step = read_line(apply_dir .. "/next")
    local last = read_line(apply_dir .. "/last")
    if next_step and last then
      return "REBASE " .. next_step .. "/" .. last
    end
    return "REBASE"
  end
end

local function operation_text(dir)
  if file_exists(dir .. "/MERGE_HEAD") then
    return "MERGE"
  end
  return rebase_label(dir) or ""
end

local function poll()
  local text = git_dir and operation_text(git_dir) or ""
  if text == vim.g.is_it_merge then
    return
  end
  vim.g.is_it_merge = text
end

local function resolve_git_dir()
  local dir = start_dir()
  if start_key == dir then
    return
  end
  start_key = dir
  git_dir = find_git_dir(dir)
  poll()
end

function M.lualine_component()
  return {
    function()
      return vim.g.is_it_merge or ""
    end,
    cond = function()
      return vim.g.is_it_merge ~= nil and vim.g.is_it_merge ~= ""
    end,
    color = { fg = "#ec5f67", gui = "bold" },
  }
end

timer = vim.uv.new_timer()
---@diagnostic disable-next-line: need-check-nil
timer:start(INTERVAL_MS, INTERVAL_MS, vim.schedule_wrap(poll))

vim.api.nvim_create_autocmd({ "BufEnter", "DirChanged" }, {
  group = vim.api.nvim_create_augroup("IsItMerge", { clear = true }),
  callback = resolve_git_dir,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("IsItMergeStop", { clear = true }),
  callback = function()
    if timer then
      timer:stop()
      timer:close()
      timer = nil
    end
  end,
})

resolve_git_dir()

return M
