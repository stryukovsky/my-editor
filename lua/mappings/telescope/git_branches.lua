local actions = require "telescope.actions"
local wrap_telescope_action = require("mappings.telescope_action_wrapper")

return {
  n = require "mappings.telescope.git_branches_actions",
  i = {
    ["<cr>"] = wrap_telescope_action(actions.git_switch_branch),
  },
}
