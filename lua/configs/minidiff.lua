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
require("configs.minidiff_history").setup()
require("configs.large_hunks_viewer").setup()

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
  local range = MiniDiff.get_contiguous_hunk_range_at_cursor(0)
  if not range then
    return
  end
  pcall(MiniDiff.do_hunks, 0, "reset", { line_start = range.from, line_end = range.to })
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
  notify.replace("minidiff.overlay", "MiniDiff", overlay_wanted() and "Hunk overlay on" or "Hunk overlay off", vim.log.levels.INFO)
end

function M.lualine_hunks()
  local summary = vim.b.minidiff_summary
  local total = summary and summary.n_ranges or 0
  if total == 0 then
    return ""
  end
  local _, idx = MiniDiff.get_contiguous_hunk_range_at_cursor(0)
  if idx then
    return string.format("hunks: %d/%d", idx, total)
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
  if direction > 0 then
    local _, idx = MiniDiff.get_contiguous_hunk_range_at_cursor(0)
    local total = vim.b.minidiff_summary and vim.b.minidiff_summary.n_ranges or 0
    if idx and idx == total then
      if vim.b.minidiff_review then
        notify.send("MiniDiff", "Last hunk, focusing review file list", vim.log.levels.INFO)
        require("configs.minidiff_review").focus_list()
        return
      end
      notify.send("MiniDiff", "It was last hunk, so neogit", vim.log.levels.INFO)
      require("utils.open_neogit_status")()
      return
    end
  end
  MiniDiff.goto_hunk(direction > 0 and "next" or "prev")
  vim.cmd "normal! zz"
end

return M
