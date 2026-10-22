local notify = require "configs.notify"

local M = {}

---Same Yes/No dialog as neo-tree delete (`vim.fn.confirm`).
---@param message string
---@return boolean
function M.confirmed(message)
  return vim.fn.confirm(message, "&Yes\n&No") == 1
end

---@param title string
---@return fun(message: string, level?: integer)
function M.notifier(title)
  return function(message, level)
    notify.send(title, message, level or vim.log.levels.INFO)
  end
end

return M
