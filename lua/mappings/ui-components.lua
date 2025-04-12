local map = require "mappings.map"
local dapui = require "dapui"
local term = require "nvchad.term"
local neotest = require "neotest"
local trouble = require "trouble"

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

local bottom_component_callback_close = function() end
local right_component_callback_close = function() end

local function toggle_views(view, opts)
  if trouble.is_open(view) then
    trouble.close(view)
  else
  end
end

-- neotest
local neotest_summary_opened = false
map("n", "<A-t>", function()
  if neotest_summary_opened then
    neotest.summary.close()
  else
    right_component_callback_close()
    right_component_callback_close = function()
      neotest.summary.close()
    end
    neotest.summary.open()
  end
  neotest_summary_opened = not neotest_summary_opened
end, { desc = "Test show summary" })

local neotest_output_opened = false
map("n", "<A-T>", function()
  if neotest_output_opened then
    neotest.output_panel.close()
  else
    bottom_component_callback_close()
    bottom_component_callback_close = function()
      neotest.output_panel.close()
    end
    neotest.output_panel.open()
  end
  neotest_output_opened = not neotest_output_opened
end, { desc = "Test show output" })

-- trouble plugin
-- "<cmd>Trouble diagnostics toggle focus=true<CR>"
map("n", "<A-p>", function()
  if trouble.is_open "diagnostics" then
    trouble.close "diagnostics"
  else
    bottom_component_callback_close()
    bottom_component_callback_close = function()
      trouble.close "diagnostics"
    end
    trouble.open { mode = "diagnostics", focus = true }
  end
end, { desc = "trouble diagnostics" })
map("n", "<A-l>", "<cmd>Trouble symbols toggle focus=true<cr>", { desc = "trouble list structure of buffer" })
map("n", "<A-x>", "<cmd>Trouble lsp toggle focus=false win.position=right<cr>", { desc = "trouble x-ray definitions" })

-- the same stuff but telescope mode
-- local telescope_builtin = require "telescope.builtin"
-- map("n", "<A-p>", function()
--   telescope_builtin.diagnostics { bufnr = 0 }
-- end, opts "inspections on current buffer")
--
-- map("n", "<A-P>", function()
--   telescope_builtin.diagnostics {}
-- end, opts "inspections on all")
-- map("n", "<A-l>", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "telescope structure of file" })
