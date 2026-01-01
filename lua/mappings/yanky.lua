local telescope = require "telescope"

local map = require "mappings.map"
map({ "n", "v", "x" }, "<leader>pp", function()
  telescope.extensions.yank_history.yank_history { initial_mode = "normal" }
end, { desc = "yanky paste from history" })

map({ "n", "v", "x" }, "P", function()
  telescope.extensions.yank_history.yank_history { initial_mode = "normal" }
end, { desc = "yanky paste from history" })
