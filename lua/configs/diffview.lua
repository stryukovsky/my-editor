local actions = require "diffview.actions"
---@diagnostic disable-next-line: missing-fields
require("diffview").setup {
  merge_tool = {
    layout = "diff3_horizontal",
    disable_diagnostics = true,
    winbar_info = true,
  },
  file_history_panel = {
    log_options = {
      git = {
        single_file = {
          diff_merges = "first-parent",
          follow = true,
        },
        multi_file = {
          diff_merges = "first-parent",
        },
      },
    },
    win_config = {
      position = "bottom",
      height = 16,
      win_opts = {},
    },
  },
  keymaps = {
    disable_defaults = false, -- Disable the default keymaps
    view = {
      { "n", "<A-e>", actions.focus_files, { desc = "Focus files panel" } },
    },
    file_panel = {
      { "n", "<Left>", actions.close_fold, { desc = "Collapse fold" } },
      { "n", "<Right>", actions.select_entry, { desc = "Open the diff for the selected entry" } },
    },
  },
}
