local trouble = require "trouble.sources.telescope"
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local trouble_main = require "trouble"
local function open_with_trouble(bufnr)
  local picker = action_state.get_current_picker(bufnr)
  if not picker then
    return
  end
  local selection = action_state.get_selected_entry()
  if not selection then
    return
  end
  local count = picker.manager:num_results()
  if count > 1 then
    if trouble_main.is_open "lsp" then
      trouble_main.close "lsp"
    end
    if trouble_main.is_open "diagnostics" then
      trouble_main.close "diagnostics"
    end
    if trouble_main.is_open "telescope" then
      trouble_main.close "telescope"
    end
    if trouble_main.is_open "telescope_files" then
      trouble_main.close "telescope_files"
    end
    -- this stuff disables sorting
    local sort_disabler = 0
    ---@diagnostic disable-next-line: missing-fields
    trouble.open(bufnr, {
      focus = true,
      mode = "telescope_files",
      sorters = {},
      sort = function(_)
        -- function returns incrementing index of every item
        -- so basically, it keeps the order of items from telescope
        -- disabling of sorting helps better navigate from telescope choice
        -- to current item in trouble.nvim
        sort_disabler = sort_disabler + 1
        return sort_disabler
      end,
    })
    local index = 2 + picker:get_selection_row() -- This gives you the 1-based index
    vim.defer_fn(function()
      vim.api.nvim_win_set_cursor(0, { index, 0 })
    end, 200)
  else
    actions.select_default(bufnr)
    vim.defer_fn(function()
      vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
    end, 200)
  end
end

return {
  n = {
    ["<cr>"] = open_with_trouble,
  },
  i = {
    ["<cr>"] = open_with_trouble,
  },
}
