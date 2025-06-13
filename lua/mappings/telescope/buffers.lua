local actions = require "telescope.actions"
return {
  n = {
    ["<C-d>"] = actions.delete_buffer,
    ["<C-x>"] = actions.delete_buffer,
    ["x"] = actions.delete_buffer,
    ["d"] = actions.delete_buffer,
  },
  i = {
    ["<C-d>"] = actions.delete_buffer,
    ["<C-x>"] = actions.delete_buffer,
    ["x"] = actions.delete_buffer,
    ["d"] = actions.delete_buffer,
  },
}
