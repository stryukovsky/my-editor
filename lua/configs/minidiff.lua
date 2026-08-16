local MiniDiff = require "mini.diff"
local notify = require "configs.notify"

local M = {}

if vim.g.minidiff_overlay == nil then
  vim.g.minidiff_overlay = false
end

MiniDiff.setup {
  view = {
    style = "sign",
    signs = { add = "┃", change = "┃", delete = "┃" },
  },
  -- Default maps use vim.keymap.set; keep them off and bind via mappings.map.
  mappings = {
    apply = "",
    reset = "",
    textobject = "",
    goto_first = "",
    goto_prev = "",
    goto_next = "",
    goto_last = "",
  },
  options = {
    algorithm = "histogram",
    indent_heuristic = true,
    linematch = 0,
    wrap_goto = true,
  },
}

require("configs.minidiff_review").setup()
require("configs.large_hunks_viewer").setup()

---@param hunk table
---@return integer, integer
local function hunk_buf_range(hunk)
  if hunk.buf_count > 0 then
    return hunk.buf_start, hunk.buf_start + hunk.buf_count - 1
  end
  local from = math.max(hunk.buf_start, 1)
  return from, from
end

---@return integer|nil from
---@return integer|nil to
local function contiguous_range_at_cursor()
  local data = MiniDiff.get_buf_data(0)
  if not data or not data.hunks or #data.hunks == 0 then
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  local ranges = {}
  for _, hunk in ipairs(data.hunks) do
    local from, to = hunk_buf_range(hunk)
    local last = ranges[#ranges]
    if last and from <= last.to + 1 then
      last.to = math.max(last.to, to)
    else
      table.insert(ranges, { from = from, to = to })
    end
  end
  for _, range in ipairs(ranges) do
    if lnum >= range.from and lnum <= range.to then
      return range.from, range.to
    end
  end
end

local function overlay_wanted()
  return vim.g.minidiff_overlay == true
end

---@param buf integer
local function sync_overlay(buf)
  local data = MiniDiff.get_buf_data(buf)
  if not data then
    return
  end
  if data.overlay ~= overlay_wanted() then
    pcall(MiniDiff.toggle_overlay, buf)
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "MiniDiffUpdated",
  group = vim.api.nvim_create_augroup("MiniDiffOverlayGlobal", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    if buf == 0 then
      buf = vim.api.nvim_get_current_buf()
    end
    sync_overlay(buf)
  end,
})

function M.preview()
  require("configs.large_hunks_viewer").view_hunk()
end

function M.reset_hunk()
  if vim.b.minidiff_review then
    return
  end
  local from, to = contiguous_range_at_cursor()
  if not from or not to then
    return
  end
  pcall(MiniDiff.do_hunks, 0, "reset", { line_start = from, line_end = to })
end

function M.reset_buffer()
  if vim.b.minidiff_review then
    return
  end
  pcall(MiniDiff.do_hunks, 0, "reset")
end

function M.select()
  MiniDiff.textobject()
end

function M.toggle_overlay()
  vim.g.minidiff_overlay = not overlay_wanted()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    sync_overlay(buf)
  end
  notify.replace(
    "minidiff.overlay",
    "MiniDiff",
    overlay_wanted() and "Hunk overlay on" or "Hunk overlay off",
    vim.log.levels.INFO
  )
end

function M.lualine_hunks()
  local data = MiniDiff.get_buf_data(0)
  if not data or not data.hunks or #data.hunks == 0 then
    return ""
  end
  local total = #data.hunks
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  for i, hunk in ipairs(data.hunks) do
    local from, to = hunk_buf_range(hunk)
    if lnum >= from and lnum <= to then
      return string.format("hunks: %d/%d", i, total)
    end
  end
  return string.format("hunks: %d", total)
end

---@param direction 1|-1
function M.nav(direction)
  if vim.wo.diff then
    vim.cmd.normal { direction > 0 and "]c" or "[c", bang = true }
    vim.cmd "normal! zz"
    return
  end
  if MiniDiff.get_buf_data(0) == nil then
    return
  end
  MiniDiff.goto_hunk(direction > 0 and "next" or "prev")
  vim.cmd "normal! zz"
end

return M
