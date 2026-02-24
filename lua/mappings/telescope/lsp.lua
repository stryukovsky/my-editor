local wrap_telescope_action = require("mappings.telescope_action_wrapper")
local trouble_integration = require("mappings.telescope.trouble_integration")

-- local function open_with_trouble(bufnr)
--   local picker = action_state.get_current_picker(bufnr)
--   if not picker then
--     return
--   end
--   local selection = action_state.get_selected_entry()
--   if not selection then
--     return
--   end
--   local count = picker.manager:num_results()
--   -- vim.print(vim.inspect(selection))
--   if count > 1 then
--     trouble.close()
--     ---@diagnostic disable-next-line: missing-fields
--     trouble_telescope.open(bufnr, { focus = false })
--   end
--   vim.defer_fn(function()
--     vim.cmd("edit! " .. selection.filename)
--   end, 200)
--   vim.defer_fn(function()
--     vim.api.nvim_win_set_cursor(0, { selection.lnum, selection.col })
--   end, 250)
-- end

return {
  n = {
    ["<cr>"] = wrap_telescope_action(trouble_integration),
  },
  i = {
    ["<cr>"] = wrap_telescope_action(trouble_integration),
  },
}
