local M = {}

function M.setup()
  require("dashboard").setup {
    theme = "hyper",
    hide = { statusline = true },
    config = {
      week_header = {
        enable = true,
      },
      project = { enable = false },
      mru = { enable = false },
    },
  }
end

---@param win? integer
function M.open_in(win)
  win = win or 0
  if win ~= 0 and not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd.Dashboard()
  end)
end

local function enew_or_dashboard(...)
  M.open_in(0)
end

-- Barbar/oil call `vim.cmd.enew`; `:enew` is rewritten to `:Enew` below.
vim.cmd.enew = enew_or_dashboard


-- NOTE: this stuff disable :enew command - create dashboard instead
--
-- vim.api.nvim_create_user_command("Enew", function()
--   enew_or_dashboard()
-- end, { bang = true, desc = "Open dashboard" })
-- vim.cmd [[cnoreabbrev <expr> enew (getcmdtype() == ':' && getcmdline() =~# '^\s*enew$') ? 'Enew' : 'enew']]

M.setup()

return M
