
-- terminal
--
local map = require("mappings.map")
local dapui = require "dapui"

-- show git history
map("n", "<A-c>", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<A-g>", "<cmd>Telescope git_branches<CR>", { desc = "telescope git branches" })
map("n", "<A-k>", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<A-u>", "<cmd>Telescope undo<CR>", { desc = "telescope undo tree" })
map("n", "<A-f>", "<cmd>Telescope live_grep<CR>", { desc = "telescope search in project" })
map("n", "<A-h>", "<cmd>DiffviewFileHistory<CR>", { desc = "diffview file history" })
map("n", "<A-m>", "<cmd>DiffviewOpen<CR>", { desc = "diffview open merge tool" })

-- windows focus move
map({ "n", "v", "t" }, "<A-a>", "<C-W>h", { desc = "switch window left" })
map({ "n", "v", "t" }, "<A-d>", "<C-W>l", { desc = "switch window right" })
map({ "n", "v", "t" }, "<A-s>", "<C-W>j", { desc = "switch window down" })
map({ "n", "v", "t" }, "<A-w>", "<C-W>k", { desc = "switch window up" })

map({ "n", "v", "t" }, "+", "<C-W>3>", { desc = "window width increase" })
map({ "n", "v", "t" }, "_", "<C-W>3<", { desc = "window width decrease" })


local dapui_state_is_opened = false

-- toggle dapui
map("n", "<A-r>", function()
  if (dapui_state_is_opened) then
  dapui.close()
  vim.cmd "NvimTreeOpen"
  else
  dapui.open()
  vim.cmd "NvimTreeClose"
  end
  dapui_state_is_opened = not dapui_state_is_opened
end, { desc = "debug close view" })

map({ "n", "t" }, "<A-t>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- focus nvimtree 
map({ "n", "t" }, "<A-e>", function()
  dapui.close()
  vim.cmd "NvimTreeFocus"
end, { desc = "nvimtree focus window" })
