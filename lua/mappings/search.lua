local map = require "mappings.map"
local telescope = require "telescope"
local get_visual_selection = require "utils.get_visual_selection"

-- search and replace
map("n", "<leader>fw", function()
  local word = vim.fn.expand "<cword>"
  if vim.trim(word) == "" then
    vim.notify("No word under cursor", vim.log.levels.WARN)
    return
  end
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
  require("telescope.builtin").current_buffer_fuzzy_find {
    default_text = word,
    initial_mode = "normal",
  }
end, { desc = "telescope search selection in current buffer" })

map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>", { desc = "telescope find all files" })
