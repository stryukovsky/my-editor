---@diagnostic disable: missing-fields
local gitconflict = require "git-conflict"
local close_trouble = require "utils.close_trouble"
gitconflict.setup {
  default_mappings = {
    ours = "<leader>co",
    theirs = "<leader>ct",
    none = "<leader>c0",
    both = "<leader>cb",
    next = "]x",
    prev = "[x",
  },
  default_commands = true, -- disable commands created by this plugin
  disable_diagnostics = true, -- This will disable the diagnostics in a buffer whilst it is conflicted
  list_opener = function()
    close_trouble()
    vim.cmd "Trouble qflist open"
  end, -- command or function to open the conflicts list
  highlights = { -- They must have background color, otherwise the default color will be used
    -- incoming = "DiffAdd",
    -- current = "DiffText",
  },
}
