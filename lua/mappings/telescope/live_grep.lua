local open_with_trouble = require("trouble.sources.telescope").open
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
return {
  n = {
    ["<cr>"] = function(bufnr, opts)
      local picker = action_state.get_current_picker(prompt_bufnr)
      open_with_trouble(bufnr, { focus = true })
      vim.schedule(function()
        actions.select_default(bufnr, opts)
      end)
    end,
  },
  i = {
    ["<cr>"] = function(bufnr, opts)
      open_with_trouble(bufnr, { focus = true, mode = "telescope_files" })
      -- vim.schedule(function()
      --   actions.select_default(bufnr, opts)
      -- end)
    end,
  },
}
