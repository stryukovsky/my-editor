local map = require "mappings.map"
local dapui = require "dapui"
local term = require "nvchad.term"
local neotest = require "neotest"
local trouble = require "trouble"
local kulala = require "kulala"
local kulala_ui = require "kulala.ui"
local new_branch = require "ui.new_branch"

-- show git history
map("n", "<A-c>", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<A-g>", "<cmd>Telescope git_branches<CR>", { desc = "telescope git branches" })
map("n", "<A-k>", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<A-u>", "<cmd>Telescope undo<CR>", { desc = "telescope undo tree" })
map("n", "<A-f>", "<cmd>Telescope live_grep<CR>", { desc = "telescope search in project" })
map("n", "<A-z>", "<cmd>Telescope oldfiles<CR>", { desc = "telescope previously opened files" })
map("n", "<leader><leader>", "<cmd>Telescope buffers only_cwd=true<CR>", { desc = "telescope previously opened files" })
map("n", "<A-j>", "<cmd>TodoTelescope<CR>", { desc = "telescope TODOs" })

local dialog_component_callback_close = function() end

local kulala_state_is_opened = false
map("n", "<A-y>", function()
  if kulala_state_is_opened then
    kulala_ui.close_kulala_buffer()
  else
    dialog_component_callback_close()
    kulala.open()
    dialog_component_callback_close = function()
      kulala_state_is_opened = false
      kulala_ui.close_kulala_buffer()
    end
  end
  kulala_state_is_opened = not kulala_state_is_opened
end, { desc = "kulala toggle" })

map("n", "<A-Y>", function()
  if kulala_state_is_opened then
    kulala_ui.close_kulala_buffer()
  else
    dialog_component_callback_close()
    kulala_ui.open() -- this is key difference - it runs query on cursor
    dialog_component_callback_close = function()
      kulala_state_is_opened = false
      kulala_ui.close_kulala_buffer()
    end
  end
  kulala_state_is_opened = not kulala_state_is_opened
end, { desc = "kulala toggle with sending request" })

local fileHistoryOpened = false
map("n", "<A-h>", function()
  if fileHistoryOpened then
    vim.cmd "tabc"
    dialog_component_callback_close = function() end
  else
    dialog_component_callback_close()
    vim.cmd "DiffviewFileHistory"
    dialog_component_callback_close = function()
      fileHistoryOpened = false
      vim.cmd "tabc"
    end
  end
  fileHistoryOpened = not fileHistoryOpened
end, { desc = "diffview file history" })

local diffViewOpened = false
map("n", "<A-m>", function()
  if diffViewOpened then
    vim.cmd "tabc"
    dialog_component_callback_close = function() end
  else
    dialog_component_callback_close()
    dialog_component_callback_close = function()
      diffViewOpened = false
      vim.cmd "tabc"
    end
    vim.cmd "DiffviewOpen"
  end
  diffViewOpened = not diffViewOpened
end, { desc = "diffview open merge tool" })

-- windows focus move
map({ "n", "v", "t" }, "<A-a>", "<C-W>h", { desc = "switch window left" })
map({ "n", "v", "t" }, "<A-d>", "<C-W>l", { desc = "switch window right" })
map({ "n", "v", "t" }, "<A-s>", "<C-W>j", { desc = "switch window down" })
map({ "n", "v", "t" }, "<A-w>", "<C-W>k", { desc = "switch window up" })

map({ "n", "v", "t" }, "+", "<C-W>3>", { desc = "window width increase" })
map({ "n", "v", "t" }, "_", "<C-W>3<", { desc = "window width decrease" })

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
end, { desc = "system resource inspector" })

-- focus nvimtree
map({ "n", "t" }, "<A-e>", function()
  dapui.close()
  vim.cmd "NvimTreeFocus"
end, { desc = "nvimtree focus window" })

local bottom_component_callback_close = function() end
local right_component_callback_close = function() end

local dapui_state_is_opened = false
-- toggle dapui
map("n", "<A-r>", function()
  if dapui_state_is_opened then
    dapui.close()
    vim.cmd "NvimTreeOpen"
  else
    bottom_component_callback_close()
    dapui.open()
    bottom_component_callback_close = function()
      dapui_state_is_opened = false
      dapui.close()
    end
    vim.cmd "NvimTreeClose"
  end
  dapui_state_is_opened = not dapui_state_is_opened
end, { desc = "debug close view" })

-- neotest
local neotest_summary_opened = false
map("n", "<A-t>", function()
  if neotest_summary_opened then
    neotest.summary.close()
  else
    right_component_callback_close()
    right_component_callback_close = function()
      neotest_summary_opened = false
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
      neotest_output_opened = false
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

map("n", "<A-l>", function()
  if trouble.is_open "symbols" then
    trouble.close "symbols"
  else
    right_component_callback_close()
    right_component_callback_close = function()
      trouble.close "symbols"
    end
    trouble.open { mode = "symbols", focus = true }
  end
end, { desc = "trouble list structure of buffer" })

map("n", "<A-x>", function()
  if trouble.is_open "lsp" then
    trouble.close "lsp"
  else
    right_component_callback_close()
    right_component_callback_close = function()
      trouble.close "lsp"
    end
    trouble.open { mode = "lsp", focus = false, win = { position = "right" } }
  end
end, { desc = "trouble x-ray definitions" })

map("n", "<A-/>", "<cmd>SessionSearch<cr>", { desc = "open sessions available" })
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
--

map("n", "<leader>gb", function()
  new_branch()
end)
