local trouble = require "trouble.sources.telescope"
local action_state = require "telescope.actions.state"

local function open_with_trouble(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if not picker then
    return
  end
  local selection = action_state.get_selected_entry()
  if not selection then
    return
  end
  -- vim.print(vim.inspect(picker))
  local count = picker.manager:num_results()
  if count > 1 then
    ---@diagnostic disable-next-line: missing-fields
    trouble.open(bufnr, { focus = false, mode = "telescope_files" })
  end
  vim.defer_fn(function()
    vim.cmd("edit! " .. selection.path)
  end, 200)
  vim.defer_fn(function()
    vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
  end, 250)
end

return {
  n = {
    ["<cr>"] = open_with_trouble,
  },
  i = {
    ["<cr>"] = open_with_trouble,
  },
}
