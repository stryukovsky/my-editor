local state = require "llm.state"
local M = {}

M.is_open = function()
  if not state.llm.winid then
    return false
  else
    return true
  end
end

return M
