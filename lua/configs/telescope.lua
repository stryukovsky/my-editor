vim.api.nvim_create_autocmd("User", {
  pattern = "TelescopePreviewerLoaded",
  callback = function()
    vim.wo.wrap = true
    vim.wo.linebreak = true
  end,
})
local make_entry = require "telescope.make_entry"

local function entry_for_filesearch(entry)
  local original_entry = make_entry.gen_from_vimgrep {}(entry)

  -- Override the display function to exclude the match text
  original_entry.display = function(display_entry)
    local display_string = string.format("%s:%d:%d", display_entry.filename, display_entry.lnum, display_entry.col)
    -- You can also add icons or colors here if desired
    return display_string
  end

  return original_entry
end

require("telescope").setup {
  -- the rest of your telescope config goes here
  defaults = {
    prompt_prefix = "   ",
    sorting_strategy = "ascending",

    layout_config = {
      horizontal = {
        prompt_position = "top",
        preview_width = 0.55,
      },
      width = 0.87,
      height = 0.80,
    },
    path_display = {
      filename_first = {
        reverse_directories = false,
      },
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
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {
        -- even more opts
        initial_mode = "normal",
      },
    },
  },
  pickers = {
    git_branches = {
      wrap_results = true,
      initial_mode = "normal",
      mappings = require "mappings.telescope.git_branches",
    },
    live_grep = {
      wrap_results = true,
      mappings = require "mappings.telescope.live_grep",
      entry_maker = entry_for_filesearch,
    },
    lsp_references = {
      wrap_results = true,
      initial_mode = "normal",
      mappings = require "mappings.telescope.lsp",
    },
    lsp_definitions = {
      wrap_results = true,
      initial_mode = "normal",
      mappings = require "mappings.telescope.lsp",
    },
    lsp_type_definitions = {
      wrap_results = true,
      initial_mode = "normal",
      mappings = require "mappings.telescope.lsp",
    },
    git_commits = {
      wrap_results = true,
      initial_mode = "normal",
    },
  },
}
require("telescope").load_extension "ui-select"
require("telescope").load_extension "grapple"
