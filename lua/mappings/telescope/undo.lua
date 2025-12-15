local actions = require "telescope-undo.actions"
local wrap_telescope_action = require("mappings.telescope_action_wrapper")
return {
  n = {
    ["<cr>"] = wrap_telescope_action(actions.restore),
  },
  i = {
    ["<cr>"] = wrap_telescope_action(actions.restore),
  },
}
