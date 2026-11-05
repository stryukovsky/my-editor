local M = {}

function M.setup()
  require("dashboard").setup {
    theme = "hyper",
    hide = { statusline = false, tabline = false },
    config = {
      week_header = {
        enable = true,
      },
      shortcut = {
        {
          icon = "󰜮 ",
          desc = "Fetch",
          group = "DashboardShortCut",
          key = "f",
          action = function()
            local git_fetch = require "moonshine.git.fetch"
            local notify = require "integrations.notify"
            if not git_fetch.is_git_repo() then
              notify.send("Git fetch", "Not a git repository", vim.log.levels.WARN)
              return
            end
            notify.replace("git-fetch", "Git fetch", "Fetching updates from remote...", vim.log.levels.WARN)
            git_fetch.git_fetch(function(success)
              vim.schedule(function()
                local message = success and "Fetch completed" or "Fetch skipped or failed"
                notify.replace("git-fetch", "Git fetch", message, success and vim.log.levels.INFO or vim.log.levels.WARN)
              end)
            end)
          end,
        },
        {
          icon = "󰜮 ",
          desc = "Pull",
          group = "DashboardShortCut",
          key = "p",
          action = function()
            local git_fetch = require "moonshine.git.fetch"
            local notify = require "integrations.notify"
            if not git_fetch.is_git_repo() then
              notify.send("Git pull", "Not a git repository", vim.log.levels.WARN)
              return
            end
            if git_fetch.is_git_operation_in_progress() then
              notify.send("Git pull", "Another Git operation is in progress", vim.log.levels.WARN)
              return
            end
            require("moonshine.git.commands").pull()
          end,
        },
      },
      project = { enable = false },
      mru = { enable = false },
      footer = function()
        return require("moonshine.gospel").footer()
      end,
    },
  }
end

local function center_dashboard_windows()
  local widths = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "dashboard" then
      local width = vim.api.nvim_win_get_width(win)
      widths[buf] = math.min(widths[buf] or width, width)
    end
  end

  for buf, width in pairs(widths) do
    local modifiable = vim.bo[buf].modifiable
    local changed = false
    local banner_shift
    for row, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      local indent, content = line:match "^( *)(%S.-)%s*$"
      if content then
        local padding = math.max(0, math.floor((width - vim.api.nvim_strwidth(content)) / 2))
        -- The weekday banner is the first block. Move its rows by the same
        -- amount so the leading and trailing spaces still shape the letters.
        if banner_shift == nil then
          banner_shift = vim.startswith(content, "█") and (padding - #indent) or false
        end
        if banner_shift then
          padding = #indent + banner_shift
        end
        if #indent ~= padding then
          if not changed then
            vim.bo[buf].modifiable = true
            changed = true
          end
          -- Replace only the padding so the shortcut and text highlights move with the text.
          vim.api.nvim_buf_set_text(buf, row - 1, 0, row - 1, #indent, { string.rep(" ", padding) })
        end
      elseif banner_shift then
        banner_shift = false
      end
    end
    if changed then
      vim.bo[buf].modifiable = modifiable
      vim.bo[buf].modified = false
    end
  end
end

-- Hyper centers against the editor width. Recenter when a sidebar changes the window width.
local layout = vim.api.nvim_create_augroup("DashboardWindowLayout", { clear = true })
vim.api.nvim_create_autocmd("User", {
  group = layout,
  pattern = "DashboardLoaded",
  callback = center_dashboard_windows,
})
vim.api.nvim_create_autocmd("WinResized", {
  group = layout,
  callback = center_dashboard_windows,
})

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
