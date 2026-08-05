local map = require "mappings.map"

local function open_history()
  local notifications = require("notify").history()
  local lines = {}

  if #notifications == 0 then
    table.insert(lines, "No notifications in this session.")
  end

  for _, notification in ipairs(notifications) do
    local timestamp = os.date("%Y-%m-%d %H:%M:%S", notification.time)
    local title = table.concat(notification.title or {}, " ")
    table.insert(lines, ("%s [%s] %s"):format(timestamp, notification.level, title))
    vim.list_extend(lines, notification.message)
    table.insert(lines, "")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "notify-history"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = false
  vim.api.nvim_set_current_buf(buf)

  local ok = pcall(vim.api.nvim_buf_set_name, buf, "notify-history")
  if not ok then
    vim.api.nvim_buf_set_name(buf, "notify-history-" .. math.random(9999))
  end
end

map("n", "<leader>notify", open_history, { desc = "Notify show session history" })
