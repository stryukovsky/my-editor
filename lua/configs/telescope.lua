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
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = "smart_case", -- or "ignore_case" or "respect_case"
      -- the default case_mode is "smart_case"
    },
  },
  pickers = {
    git_branches = {
      mappings = require "mappings.telescope.git_branches",
    },
    live_grep = {
      mappings = require "mappings.telescope.live_grep",
    },
  },
}
