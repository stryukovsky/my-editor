local actions = require "telescope-undo.actions"

return {
  n = {
    ["<cr>"] = actions.restore,
  },
  i = {
    ["<cr>"] = actions.restore,
  },
}
