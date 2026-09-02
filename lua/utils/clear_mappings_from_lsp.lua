local map = require "mappings.map"
local navigation_repeat = require "utils.navigation_repeat"

local M = {}

---@param bufnr integer
function M.clear_mappings_from_lsp(bufnr)
  pcall(function()
    vim.keymap.del("n", "]]", { buffer = bufnr })
  end)

  pcall(function()
    vim.keymap.del("n", "[[", { buffer = bufnr })
  end)

  pcall(function()
    map("n", "]]", navigation_repeat.repeat_next, {
      buffer = bufnr,
      desc = "Repeat next navigation",
    })
  end)

  pcall(function()
    map("n", "[[", navigation_repeat.repeat_previous, {
      buffer = bufnr,
      desc = "Repeat previous navigation",
    })

  end)
end

return M
