local defaults = require "debug_output.default"

local M = {
  options = vim.deepcopy(defaults),
}

---@param options? table
function M.setup(options)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), options or {})
end

return M
