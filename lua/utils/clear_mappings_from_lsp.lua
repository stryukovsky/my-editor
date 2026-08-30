local map = require "mappings.map"
local navigation_repeat = require "utils.navigation_repeat"

local M = {}

---@param bufnr integer
function M.clear_mappings_from_lsp(bufnr)
  local mapping = vim.api.nvim_buf_call(bufnr, function()
    return vim.fn.maparg("]]", "n", false, true)
  end)
  if mapping then
    vim.keymap.del("n", "]]", { buffer = bufnr })
  end
  map("n", "]]", navigation_repeat.repeat_last, {
    buffer = bufnr,
    desc = "Repeat last navigation",
  })
end

return M
