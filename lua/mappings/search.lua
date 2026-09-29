local map = require "mappings.map"
local get_visual_selection = require "utils.get_visual_selection"

-- search and replace
map("n", "<leader>fw", function()
  local word = vim.fn.expand "<cword>"
  if vim.trim(word) == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end
  require("utils.ui_prevent_mess")()
  require("telescope.builtin").current_buffer_fuzzy_find {
    default_text = word,
    initial_mode = "normal",
  }
end, { desc = "telescope search word in current buffer" })

map("x", "<leader>fw", function()
  local word = get_visual_selection()
  if vim.trim(word) == "" then
    vim.notify("No selection under cursor", vim.log.levels.WARN)
    return
  end
  require("utils.ui_prevent_mess")()
  require("telescope.builtin").current_buffer_fuzzy_find {
    default_text = word,
    initial_mode = "normal",
  }
end, { desc = "telescope search selection in current buffer" })

map("n", "<leader>fall", function()
  require("utils.ui_prevent_mess")()
  require("telescope.builtin").find_files {
    hidden = true,
    no_ignore = true,
    no_ignore_parent = true,
    follow = true,
    prompt_title = "Find all files",
  }
end, { desc = "telescope find all files including ignored" })
