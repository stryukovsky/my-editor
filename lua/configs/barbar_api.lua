local api = require "barbar.api"
local bdelete = require("barbar.bbye").bdelete
local render = require "barbar.ui.render"

local M = {}

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

return M
