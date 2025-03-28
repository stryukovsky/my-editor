local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

return {
  n = {
    ["<cr>"] = actions.git_switch_branch,
  },
  i = {
    ["<cr>"] = actions.git_switch_branch,
    ["<C-d>"] = function() -- show diffview comparing the selected branch with the current branch
      -- Open in diffview
      local entry = action_state.get_selected_entry()
      -- close Telescope window properly prior to switching windows
      actions.close(vim.api.nvim_get_current_buf())
      vim.cmd(("DiffviewOpen %s.."):format(entry.value))
    end,
  },
}
