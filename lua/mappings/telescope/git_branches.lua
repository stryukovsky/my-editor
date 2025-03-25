
local actions = require "telescope.actions"

return {
  n = {
    ["<cr>"] = actions.git_switch_branch,
  },
  i = {
    ["<cr>"] = actions.git_switch_branch,
  },
}
