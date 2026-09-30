---@diagnostic disable: missing-fields
local gitconflict = require "git-conflict"
local close_trouble_succeeded = require "utils.close_trouble_succeeded"
local ui_prevent_mess = require "utils.ui_prevent_mess"

-- setup() calls nvim_get_hl_by_name before the colorscheme exists.
local hl = vim.api.nvim_set_hl
hl(0, "GitConflictCurrent", { bg = "#e5d5a6", fg = "#5d5140" })
hl(0, "GitConflictCurrentLabel", { bg = "#d4c08a", fg = "#765613", bold = true })
hl(0, "GitConflictIncoming", { bg = "#e7efe0", fg = "#5d5140" })
hl(0, "GitConflictIncomingLabel", { bg = "#c5d4b4", fg = "#4a5c3a", bold = true })
hl(0, "GitConflictAncestor", { bg = "#eee4ce", fg = "#8b7d6d" })
hl(0, "GitConflictAncestorLabel", { bg = "#e0d2b4", fg = "#765613", bold = true })

gitconflict.setup {
  default_mappings = {
    ours = "<leader>co",
    theirs = "<leader>ct",
    none = "<leader>c0",
    both = "<leader>cb",
    -- ]x / [x are ours (mappings/minidiff.lua) so they join ; / <A-;> repeat.
    next = "<Plug>(git-conflict-next-unused)",
    prev = "<Plug>(git-conflict-prev-unused)",
  },
  default_commands = true, -- disable commands created by this plugin
  disable_diagnostics = true, -- This will disable the diagnostics in a buffer whilst it is conflicted
  list_opener = function()
    if not close_trouble_succeeded() then
      return
    end
    ui_prevent_mess()
    vim.cmd "Trouble qflist open focus=true"
  end, -- command or function to open the conflicts list
  highlights = { -- Need a background, or the plugin falls back to its own blue/green.
    current = "GitConflictCurrent",
    incoming = "GitConflictIncoming",
    ancestor = "GitConflictAncestor",
  },
}
