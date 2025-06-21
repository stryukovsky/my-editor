local trouble = require("trouble.sources.telescope")
local action_state = require "telescope.actions.state"

local function open_with_trouble(bufnr)
  local selection = action_state.get_selected_entry()
---@diagnostic disable-next-line: missing-fields
  trouble.open(bufnr, { focus = false, mode = "telescope_files" })
  vim.schedule(function()
    vim.cmd("edit! " .. selection.path)
    vim.api.nvim_win_set_cursor(0, {selection.lnum, selection.col})
  end)
end

return {
  n = {
    ["<cr>"] = open_with_trouble,
  },
  i = {
    ["<cr>"] = open_with_trouble,
  },
}
