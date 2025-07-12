local actions = require "telescope.actions"

return {
  n = require "mappings.telescope.git_branches_actions",
  i = {
    ["<cr>"] = actions.git_switch_branch,
  },
}
