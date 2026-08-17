local M = {}

function M.setup()
  require("dashboard").setup {
    theme = "hyper",
    hide = { statusline = true, tabline = false },
    config = {
      week_header = {
        enable = true,
      },
      project = { enable = false },
      mru = { enable = false },
    },
  }
end

local function prepare_dashboard_buf()
  vim.cmd.stopinsert()
  if vim.bo.filetype == "dashboard" then
    return false
  end
  -- dashboard-nvim instance() no-ops when the buffer is not modifiable.
  if vim.bo.filetype ~= "" or vim.api.nvim_buf_get_name(0) ~= "" or not vim.bo.modifiable then
    vim.api.nvim_win_set_buf(0, vim.api.nvim_create_buf(true, false))
  end
  -- Second Dashboard() otherwise errors: "Command already exists".
  pcall(vim.api.nvim_del_user_command, "DashboardUpdateFooter")
  pcall(vim.api.nvim_del_user_command, "DbProjectDelete")
  return true
end

---@param win? integer
---@param opts? { isolate?: boolean }
function M.open_in(win, opts)
  win = win or 0
  opts = opts or {}
  if win ~= 0 and not vim.api.nvim_win_is_valid(win) then
    return
  end
  vim.api.nvim_win_call(win, function()
    if not prepare_dashboard_buf() then
      return
    end
    vim.cmd.Dashboard()
    if not opts.isolate then
      return
    end
    -- `:tabnew` / scope.nvim can leave the previous tab's file listed here.
    local dash = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if buf ~= dash and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
        vim.bo[buf].buflisted = false
      end
    end
    pcall(function()
      require("scope.core").revalidate()
    end)
  end)
end

local function enew_or_dashboard(...)
  M.open_in(0)
end

-- Barbar/oil call `vim.cmd.enew`; `:enew` is rewritten to `:Enew` below.
vim.cmd.enew = enew_or_dashboard

-- `:tabnew` does not go through `enew`. Empty new tabs should still get the dashboard.
local pending_empty_tab = false
vim.api.nvim_create_autocmd("TabNew", {
  callback = function(ev)
    pending_empty_tab = ev.file == nil or ev.file == ""
  end,
})
vim.api.nvim_create_autocmd("TabNewEntered", {
  callback = function()
    if not pending_empty_tab then
      return
    end
    pending_empty_tab = false
    vim.schedule(function()
      M.open_in(0, { isolate = true })
    end)
  end,
})

-- NOTE: this stuff disable :enew command - create dashboard instead
--
-- vim.api.nvim_create_user_command("Enew", function()
--   enew_or_dashboard()
-- end, { bang = true, desc = "Open dashboard" })
-- vim.cmd [[cnoreabbrev <expr> enew (getcmdtype() == ':' && getcmdline() =~# '^\s*enew$') ? 'Enew' : 'enew']]

M.setup()

return M
