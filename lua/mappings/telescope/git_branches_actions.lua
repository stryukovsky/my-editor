local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local wrap_telescope_action = require("mappings.telescope_action_wrapper")
local diff_fn = function() -- show diffview comparing the selected branch with the current branch
  -- Open in diffview
  local entry = action_state.get_selected_entry()
  -- close Telescope window properly prior to switching windows
  actions.close(vim.api.nvim_get_current_buf())
  vim.cmd(("DiffviewOpen %s.."):format(entry.value))
end

return {
  ["<cr>"] = wrap_telescope_action(actions.git_switch_branch),
  ["d"] = wrap_telescope_action(diff_fn),
  ["x"] = wrap_telescope_action(actions.git_delete_branch),
  ["m"] = wrap_telescope_action(actions.git_merge_branch),
  ["r"] = wrap_telescope_action(actions.git_rebase_branch),
}
