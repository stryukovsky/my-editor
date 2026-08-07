local M = {}

-- key -> last notification id (cleared when that notification closes)
local replace_ids = {}

function M.setup()
  vim.notify = require "notify"
end

---@param title string
---@param message string
---@param level? integer
---@param opts? table
---@return notify.Record|nil
function M.send(title, message, level, opts)
  opts = vim.tbl_extend("force", { title = title }, opts or {})
  return require("notify")(message, level or vim.log.levels.INFO, opts)
end

---Send a notification, replacing the previous one for this key if still open.
---When the toast times out / closes, the next call opens a fresh one.
---@param key string stable id, e.g. "navigation.wrap"
---@param title string
---@param message string
---@param level? integer
---@return notify.Record|nil
function M.replace(key, title, message, level)
  level = level or vim.log.levels.INFO
  local nvim_notify = require "notify"
  local prev = replace_ids[key]

  local record
  record = nvim_notify(message, level, {
    title = title,
    replace = prev,
    on_close = function()
      if record and replace_ids[key] == record.id then
        replace_ids[key] = nil
      end
    end,
  })

  -- Previous id expired: nvim-notify returns nil (and may warn). Retry fresh.
  if not record then
    replace_ids[key] = nil
    record = nvim_notify(message, level, {
      title = title,
      on_close = function()
        if record and replace_ids[key] == record.id then
          replace_ids[key] = nil
        end
      end,
    })
  end

  if record and record.id then
    replace_ids[key] = record.id
  end
  return record
end

return M
