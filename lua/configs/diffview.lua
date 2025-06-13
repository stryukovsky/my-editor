---@diagnostic disable-next-line: missing-fields
require("diffview").setup {
  view = {
    merge_tool = {
      layout = "diff3_mixed",
      disable_diagnostics = true,
      winbar_info = true,
    },
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
}
