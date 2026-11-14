local MiniDiff = require "mini.diff"
local notify = require "integrations.notify"
local feedback = require "moonshine.diff.assure_git_hunks_are_ready"

local M = {}

require("moonshine.diff.review").setup()
require("moonshine.diff.history").setup()
require("moonshine.diff.hunks").setup()

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
  group = vim.api.nvim_create_augroup(
    "MiniDiffOverlayGlobal",
    { clear = true }
  ),
  callback = function(ev)
    local buf = ev.buf
    if buf == 0 then
      buf = vim.api.nvim_get_current_buf()
    end
    sync_overlay(buf)
  end,
})

local refresh_pending = false
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniDiffStateChanged",
  group = vim.api.nvim_create_augroup("MiniDiffStatusline", { clear = true }),
  callback = function()
    if refresh_pending then
      return
    end
    refresh_pending = true
    vim.schedule(function()
      refresh_pending = false
      local lualine = package.loaded.lualine
      if lualine then
        lualine.refresh { place = { "statusline" } }
      end
      vim.cmd.redrawstatus()
    end)
  end,
})

function M.preview()
  require("moonshine.diff.hunks").view_hunk()
end

function M.reset_hunk()
  if vim.b.minidiff_review then
    return
  end
  if not feedback.ready(0) then
    return
  end
  local range = MiniDiff.get_contiguous_hunk_range_at_cursor(0)
  if not range then
    feedback.message(0, "No hunk under cursor")
    return
  end
  feedback.run(0, function()
    MiniDiff.do_hunks(
      0,
      "reset",
      { line_start = range.from, line_end = range.to }
    )
  end)
end

function M.reset_buffer()
  if vim.b.minidiff_review then
    return
  end
  if not feedback.ready(0) then
    return
  end
  feedback.run(0, function()
    MiniDiff.do_hunks(0, "reset")
  end)
end

function M.select()
  if not feedback.ready(0) then
    return
  end
  if not MiniDiff.get_contiguous_hunk_range_at_cursor(0) then
    return feedback.message(0, "No hunk under cursor")
  end
  feedback.run(0, MiniDiff.textobject)
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
  local state = MiniDiff.get_buf_state(0)
  -- These labels cover reference IO and queued work. Synchronous vim.diff()
  -- blocks UI painting, so an animation or percentage would be misleading.
  if state and state.status == "loading" then
    return "diff: loading…"
  end
  if state and state.status == "updating" then
    return "diff: updating…"
  end
  if not state or state.status ~= "ready" then
    return ""
  end
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
  if not feedback.ready(0) then
    return
  end
  if direction > 0 then
    local _, idx = MiniDiff.get_contiguous_hunk_range_at_cursor(0)
    local total = vim.b.minidiff_summary and vim.b.minidiff_summary.n_ranges
      or 0
    if idx and idx == total then
      if vim.b.minidiff_review then
        notify.send(
          "MiniDiff",
          "Last hunk, focusing review file list",
          vim.log.levels.INFO
        )
        require("moonshine.diff.review").focus_list()
        return
      end
      notify.send(
        "MiniDiff",
        "Last hunk, focusing Neo-tree git status",
        vim.log.levels.INFO
      )
      require "moonshine.utils.ui_prevent_mess"()
      require "moonshine.utils.focus_neotree"("git_status", false, {})
      return
    end
  end
  MiniDiff.goto_hunk(direction > 0 and "next" or "prev")
  vim.cmd "normal! zz"
end

return M
