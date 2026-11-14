local MiniDiff = require "mini.diff"
local feedback = require "moonshine.diff.assure_git_hunks_are_ready"

local M = {}

require("moonshine.diff.review").setup()
require("moonshine.diff.history").setup()
require("moonshine.diff.hunks").setup()

require("mini.diff.hunk_mode").setup()

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
    feedback.no_hunk(0)
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
    return feedback.no_hunk(0)
  end
  feedback.run(0, MiniDiff.textobject)
end

M.toggle_overlay = require("mini.diff.hunk_mode").toggle
M.lualine_hunks = require("mini.diff.navigation.global_navigation").statusline
M.nav = require("mini.diff.navigation.global_navigation").nav

return M
