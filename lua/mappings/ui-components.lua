local map = require "mappings.map"
local dapui = require "dapui"
local term = require "nvchad.term"
local neotest = require "neotest"
local trouble = require "trouble"
local kulala = require "kulala"
local kulala_ui = require "kulala.ui"
local oil = require("oil")
local new_branch = require "ui.new_branch"
local commit = require "ui.commit"
local telescope = require "telescope.actions"

local ui_components_modes = { "n", "t", "v", "i" }

local telescope_components = {
  { modes = ui_components_modes, shortcut = "<A-c>", command = "Telescope git_commits", desc = "telescope git commits" },
  { modes = ui_components_modes, shortcut = "<A-g>", command = "Telescope git_branches", desc = "telescope git branches" },
  { modes = ui_components_modes, shortcut = "<A-u>", command = "Telescope undo", desc = "telescope undo tree" },
  { modes = ui_components_modes, shortcut = "<A-f>", command = "Telescope live_grep", desc = "telescope search in project" },
  { modes = ui_components_modes, shortcut = "<A-z>", command = "Telescope oldfiles", desc = "telescope previously opened files" },
  { modes = ui_components_modes, shortcut = "<A-j>", command = "TodoTelescope", desc = "telescope TODOs" },
  { modes = {"n"}, shortcut = "<leader><leader>", command = "Telescope buffers only_cwd=true<CR>", desc = "telescope previously opened files" }
}

local current_opened_telescope_bufnr = 0

local dialog_component_callback_close = function() end
for _, value in ipairs(telescope_components) do
  map(value.modes, value.shortcut, function()
    if current_opened_telescope_bufnr ~= 0 then
      pcall(function()
        telescope.close(current_opened_telescope_bufnr)
      end)
      current_opened_telescope_bufnr = 0
    else
      dialog_component_callback_close()
      vim.cmd(value.command)
      current_opened_telescope_bufnr = vim.fn.bufnr()
      dialog_component_callback_close = function()
        if current_opened_telescope_bufnr ~= 0 then
          pcall(function()
            telescope.close(current_opened_telescope_bufnr)
          end)
          current_opened_telescope_bufnr = 0
        end
      end
    end
  end, { desc = value.desc })
end

local kulala_state_is_opened = false
map(ui_components_modes, "<A-y>", function()
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

map(ui_components_modes, "<A-Y>", function()
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
map(ui_components_modes, "<A-h>", function()
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
map(ui_components_modes, "<A-k>", function()
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

local oilOpened = false
map("n", "<A-o>", function ()
  if oilOpened then
      oil.close()
    dialog_component_callback_close = function() end
  else
    dialog_component_callback_close()
    dialog_component_callback_close = function()
      oilOpened = false
      oil.close()
    end
    oil.open()
  end
  oilOpened = not oilOpened
end, { desc = "oil toggle float browser"})


-- windows focus move
map(ui_components_modes, "<A-a>", "<C-W>h", { desc = "switch window left" })
map(ui_components_modes, "<A-d>", "<C-W>l", { desc = "switch window right" })
map(ui_components_modes, "<A-s>", "<C-W>j", { desc = "switch window down" })
map(ui_components_modes, "<A-w>", "<C-W>k", { desc = "switch window up" })
map("n", "+", "<C-W>3>", { desc = "window width increase" })
map("n", "_", "<C-W>3<", { desc = "window width decrease" })

local monitorStarted = false
map(ui_components_modes, "<A-i>", function()
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
map(ui_components_modes, "<A-e>", function()
  dapui.close()
  vim.cmd "NvimTreeFocus"
end, { desc = "nvimtree focus window" })

local bottom_component_callback_close = function() end
local right_component_callback_close = function() end

local dapui_state_is_opened = false
-- toggle dapui
map(ui_components_modes, "<A-r>", function()
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
map(ui_components_modes, "<A-t>", function()
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

local avante_state_opened = false
map(ui_components_modes, "<A-q>", function()
  if avante_state_opened then
    vim.cmd "AvanteToggle"
  else
    right_component_callback_close()
    right_component_callback_close = function()
      avante_state_opened = false
      vim.cmd "AvanteToggle"
    end
    vim.cmd "AvanteToggle"
  end
  avante_state_opened = not avante_state_opened
end, { desc = "Avante toggle view" })

local neotest_output_opened = false
map(ui_components_modes, "<A-T>", function()
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
map(ui_components_modes, "<A-p>", function()
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

map(ui_components_modes, "<A-l>", function()
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

map(ui_components_modes, "<A-m>", function()
  if trouble.is_open "lsp" then
    trouble.close "lsp"
  else
    right_component_callback_close()
    right_component_callback_close = function()
      trouble.close "lsp"
    end
    trouble.open { mode = "lsp", focus = false, win = { position = "right" } }
  end
end, { desc = "trouble monitor definitions" })

map(ui_components_modes, "<A-/>", "<cmd>SessionSearch<cr>", { desc = "open sessions available" })
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
end, { desc = "git new branch create&checkout" })

map("n", "<leader>gc", function()
  commit()
end, { desc = "git commit" })
