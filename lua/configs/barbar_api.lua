local bdelete = require("barbar.bbye").bdelete
local render = require "barbar.ui.render"
local notify = require "configs.notify"
local state = require "barbar.state"

local M = {}

---@param buf integer
---@return boolean
local function should_keep(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return true
  end
  if state.is_pinned(buf) then
    return true
  end
  if vim.bo[buf].buftype == "terminal" then
    return true
  end
  if vim.bo[buf].modified then
    return true
  end
  return false
end

--- Close one buffer via barbar (`:BufferClose!`).
---@param buf integer
function M.close_buffer(buf)
  if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  bdelete(true, buf)
  render.update()
end

--- Close several buffers via barbar, then refresh the tabline.
---@param buffers integer[]|table<any, integer>
function M.close_buffers(buffers)
  local valid = {}
  for _, buf in pairs(buffers or {}) do
    if type(buf) == "number" and vim.api.nvim_buf_is_valid(buf) then
      valid[#valid + 1] = buf
    end
  end
  if #valid == 0 then
    return
  end
  for _, buffer_number in pairs(valid) do
    bdelete(true, buffer_number)
  end
  render.update()
end

--- Close every tabline buffer except terminals, pinned buffers, and unsaved ones.
function M.close_unprotected()
  local to_close = {}
  for _, buf in ipairs(state.buffers) do
    if not should_keep(buf) then
      to_close[#to_close + 1] = buf
    end
  end
  if #to_close == 0 then
    notify.send("Buffers", "Nothing to close", vim.log.levels.INFO)
    return
  end
  M.close_buffers(to_close)
  notify.send("Buffers", ("Closed %d buffer%s"):format(#to_close, #to_close == 1 and "" or "s"), vim.log.levels.INFO)
end

return M
