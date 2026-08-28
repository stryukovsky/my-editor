local telescope = require "telescope"
local ui_prevent_mess = require "utils.ui_prevent_mess"

local map = require "mappings.map"
map({ "n", "v", "x" }, "<leader>pp", function()
  ui_prevent_mess()
  telescope.extensions.yank_history.yank_history { initial_mode = "normal" }
end, { desc = "yanky paste from history" })

map({ "n", "v", "x" }, "<leader>P", function()
  ui_prevent_mess()
  telescope.extensions.yank_history.yank_history { initial_mode = "normal" }
end, { desc = "yanky paste from history" })

map({"n","x"}, "y", "<Plug>(YankyYank)")
