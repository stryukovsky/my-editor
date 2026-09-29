local gitutils = require "configs.gitutils"

local M = {}

local INTERVAL_MS = 3000

vim.g.is_it_merge = ""

local git_dir ---@type string|nil
local git_root ---@type string|nil
local start_key ---@type string|nil
local timer ---@type uv.uv_timer_t|nil
local poll_gen = 0

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

---@param stdout string
---@return integer
local function parse_rg_counts(stdout)
  local n = 0
  for line in vim.gsplit(stdout, "\n", { plain = true, trimempty = true }) do
    n = n + (tonumber(line) or 0)
  end
  return n
end

---@param op string
---@param conflicts integer
---@return string
local function format_status(op, conflicts)
  if conflicts > 0 then
    if op ~= "" then
      return op .. " " .. conflicts
    end
    return "CONFLICTS " .. conflicts
  end
  return op
end

local function set_status(text)
  if text == vim.g.is_it_merge then
    return
  end
  vim.g.is_it_merge = text
end

local function poll()
  local op = git_dir and operation_text(git_dir) or ""
  if not git_root then
    set_status(op)
    return
  end

  poll_gen = poll_gen + 1
  local gen = poll_gen
  vim.system({
    "rg",
    "--count-matches",
    "--no-filename",
    "^>>>>>>>",
    ".",
  }, { cwd = git_root, text = true }, function(result)
    vim.schedule(function()
      if gen ~= poll_gen then
        return
      end
      local conflicts = 0
      if result.code == 0 then
        conflicts = parse_rg_counts(result.stdout or "")
      elseif result.code ~= 1 then
        conflicts = 0
      end
      set_status(format_status(op, conflicts))
    end)
  end)
end

local function resolve_git_dir()
  local dir = start_dir()
  if start_key == dir then
    return
  end
  start_key = dir
  git_root = select(1, gitutils.root(dir))
  git_dir = nil
  if git_root then
    local out = select(1, gitutils.run({ "rev-parse", "--absolute-git-dir" }, git_root))
    if out and vim.trim(out) ~= "" then
      git_dir = vim.fs.normalize(vim.trim(out))
    end
  end
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
