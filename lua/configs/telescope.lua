require("telescope").setup {
  -- the rest of your telescope config goes here
  defaults = {
    --     prompt_prefix = "   ",
    --     selection_caret = "",
    --     entry_prefix = "",
    sorting_strategy = "ascending",
    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
      },
      width = 0.87,
      height = 0.80,
    },
    mappings = require "mappings.telescope.defaults",
  },
  extensions_list = { "themes", "terms", "undo" },
  extensions = {
    undo = {
      mappings = require "mappings.telescope.undo",
    },
  },
  pickers = {
    git_branches = {
      mappings = require "mappings.telescope.git_branches",
    },
    buffers = {
      mappings = require "mappings.telescope.buffers",
    },
  },
}
