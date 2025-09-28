vim.api.nvim_create_user_command(
  "WhichKeyReload", -- Command name (must start with an uppercase letter)
  function(opts)
    require("configs.whichkey") -- Assuming you use 'which-key' plugin
    print("Reloaded whichkey!") -- Optional message to indicate command execution

  end,
  {
    desc = "WhichKey reload", -- Description for :command MyCommand
    nargs = "?", -- Optional arguments (e.g., "?" for 0 or 1 argument)
    complete = "file", -- Completion type (e.g., "file", "dir", "customlist")
    force = true, -- Overwrites existing command if true (default)
  }
)
