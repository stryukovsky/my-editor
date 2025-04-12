local map = require "mappings.map"
local dapui = require "dapui"
local term = require "nvchad.term"
local neotest = require("neotest")

-- show git history
map("n", "<A-c>", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<A-g>", "<cmd>Telescope git_branches<CR>", { desc = "telescope git branches" })
map("n", "<A-k>", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<A-u>", "<cmd>Telescope undo<CR>", { desc = "telescope undo tree" })
map("n", "<A-f>", "<cmd>Telescope live_grep<CR>", { desc = "telescope search in project" })
map("n", "<A-z>", "<cmd>Telescope oldfiles<CR>", { desc = "telescope previously opened files" })
map("n", "<A-q>", "<cmd>Telescope buffers only_cwd=true<CR>", { desc = "telescope previously opened files" })

local fileHistoryOpened = false
map("n", "<A-h>", function()
  if fileHistoryOpened then
    vim.cmd "tabc"
    fileHistoryOpened = false
  else
    vim.cmd "DiffviewFileHistory"
    fileHistoryOpened = true
  end
end, { desc = "diffview file history" })

local diffViewOpened = false
map("n", "<A-m>", function()
  if diffViewOpened then
    vim.cmd "tabc"
    diffViewOpened = false
  else
    vim.cmd "DiffviewOpen"
    diffViewOpened = true
  end
end, { desc = "diffview open merge tool" })

map("n", "<A-l>", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "telescope structure of file" })

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
  if dapui_state_is_opened then
    dapui.close()
    vim.cmd "NvimTreeOpen"
  else
    dapui.open()
    vim.cmd "NvimTreeClose"
  end
  dapui_state_is_opened = not dapui_state_is_opened
end, { desc = "debug close view" })

local monitorStarted = false
map({ "n", "t" }, "<A-i>", function()
  if not monitorStarted then
    monitorStarted = true
  end
  term.toggle {
    pos = "float",
    id = "floatTerm",
    cmd = "bpytop",
    float_opts = {
      relative = "editor",
      row = 0.1,
      col = 0.25,
      width = 0.5,
      height = 0.9,
      border = "single",
    },
  }
end, { desc = "terminal toggle floating term" })

-- focus nvimtree
map({ "n", "t" }, "<A-e>", function()
  dapui.close()
  vim.cmd "NvimTreeFocus"
end, { desc = "nvimtree focus window" })


-- neotest
map("n", "<A-t>", function() neotest.summary.toggle() end, {desc = "Test show summary"})
map("n", "<A-T>", function() neotest.output_panel.toggle() end, {desc = "Test show output"})
