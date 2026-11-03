-- Lualine chip: `󰏤 name` / `● name (N)` for the current tab's DAP session.

local session = require "debug_output.session"
local state = require "debug_output.state"

local M = {}

---@return string
local function text()
  local now = vim.uv.hrtime()
  if (now - state.lualine_cache.at) < state.LUALINE_TTL_NS then
    return state.lualine_cache.text
  end

  local current = session.for_tab()
  local result = ""
  if current then
    local meta = state.session_metadata[current.id]
    if not meta then
      result = "DAP"
    else
      local status_icon = session.status_icon(current.id, current, meta)
      local name = meta.name or "DAP"
      local active_count = session.active_count()
      if active_count > 1 then
        result = string.format("%s %s (%d)", status_icon, name, active_count)
      else
        result = string.format("%s %s", status_icon, name)
      end
    end
  end
  state.lualine_cache = { text = result, at = now }
  return result
end

---@class DebugOutputLualineComponent
---@field [1] fun(): string
---@field cond fun(): boolean

---@return DebugOutputLualineComponent
function M.component()
  return {
    text,
    cond = function()
      return text() ~= ""
    end,
  }
end

return M
