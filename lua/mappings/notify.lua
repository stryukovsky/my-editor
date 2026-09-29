local map = require "mappings.map"
local open_scratch = require "utils.open_scratch"

local function is_error_level(level)
  if type(level) == "number" then
    return level >= vim.log.levels.ERROR
  end
  return tostring(level or ""):upper() == "ERROR"
end

local function is_error_message_line(line)
  return line:match "^E%d+:"
    or line:match "^Error detected"
    or line:match "Error executing"
    or line:match "^Vim%(.*%):E%d+"
end

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

  open_scratch { name = "notify-history", filetype = "notify-history", lines = lines }
end

-- ERROR toasts from nvim-notify, plus :messages lines that look like Vim/Lua errors.
local function open_errors()
  local lines = {}
  local seen = {}

  local function add(line)
    if line ~= "" and not seen[line] then
      seen[line] = true
      lines[#lines + 1] = line
    end
  end

  for _, notification in ipairs(require("notify").history()) do
    if is_error_level(notification.level) then
      local timestamp = os.date("%Y-%m-%d %H:%M:%S", notification.time)
      local title = table.concat(notification.title or {}, " ")
      add(("%s [ERROR] %s"):format(timestamp, title))
      for _, msg_line in ipairs(notification.message or {}) do
        add(msg_line)
      end
      lines[#lines + 1] = ""
    end
  end

  for msg_line in vim.fn.execute("messages"):gmatch "[^\n]+" do
    if is_error_message_line(msg_line) then
      add(msg_line)
    end
  end

  local errmsg = vim.v.errmsg
  if type(errmsg) == "string" and errmsg ~= "" then
    add(errmsg)
  end

  while lines[#lines] == "" do
    lines[#lines] = nil
  end

  if #lines == 0 then
    lines = { "No errors in this session." }
  end

  open_scratch { name = "session-errors", filetype = "log", lines = lines }
end

map("n", "<leader>notify", open_history, { desc = "Notify show session history" })
map("n", "<leader>err", open_errors, { desc = "Show session errors" })
