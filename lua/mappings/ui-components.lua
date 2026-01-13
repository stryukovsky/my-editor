---@diagnostic disable: duplicate-set-field
local map = require "mappings.map"
local dapui = require "dapui"
local neotest = require "neotest"
local trouble = require "trouble"
local kulala = require "kulala"
local kulala_ui = require "kulala.ui"
local oil = require "oil"
local gitsigns_async = require "gitsigns.async"
local gitsigns_blame = require "gitsigns.actions.blame"
local neotree_command = require "neo-tree.command"
local spectre = require "spectre"
local close_telescope = require "mappings.close_telescope"
local is_normal_buffer = require "utils.is_normal_buffer"

local ui_components_modes = { "n" }

local telescope_components = {
  {
    modes = ui_components_modes,
    shortcut = "<A-m>",
    command = function()
      vim.cmd "Telescope grapple tags"
    end,
    desc = "UI telescope marks",
  },
  {
    modes = { "n" },
    shortcut = "<leader><leader>",
    command = function()
      vim.cmd "Telescope find_files"
    end,
    desc = "UI telescope files",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-c>",
    command = function()
      vim.cmd "Telescope git_commits"
    end,
    desc = "UI telescope git commits",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-g>",
    command = function()
      vim.cmd "Telescope git_branches"
    end,
    desc = "UI telescope git branches",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-u>",
    command = function()
      vim.cmd "Telescope undo"
    end,
    desc = "UI telescope undo tree",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-f>",
    command = function()
      vim.cmd "Telescope current_buffer_fuzzy_find"
    end,
    desc = "UI telescope find in current buffer",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-F>",
    command = function()
      vim.cmd "Telescope live_grep"
    end,
    desc = "UI telescope search in project",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-z>",
    command = function()
      vim.cmd "Telescope oldfiles"
    end,
    desc = "UI telescope previously opened files",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-j>",
    command = function()
      vim.cmd "TodoTelescope"
    end,
    desc = "UI telescope TODOs",
  },
}

map("n", "<leader>sa", "<cmd>Telescope spell_suggest theme=get_cursor<cr>", { desc = "Actions: spelling" })

vim.g.last_opened_telescope = ""
_G.dialog_component_callback_close = function() end
for _, value in ipairs(telescope_components) do
  map(value.modes, value.shortcut, function()
    if close_telescope() then
      if vim.g.last_opened_telescope ~= value.desc then
        value.command()
        vim.g.last_opened_telescope = value.desc
      end
    else
      _G.dialog_component_callback_close()
      value.command()
      vim.g.last_opened_telescope = value.desc
    end
    _G.dialog_component_callback_close = function()
      close_telescope()
      vim.g.last_opened_telescope = value.desc
      _G.dialog_component_callback_close = function() end
    end
  end, { desc = value.desc })
end

local kulala_state_is_opened = false
map(ui_components_modes, "<A-y>", function()
  if kulala_state_is_opened then
    kulala_ui.close_kulala_buffer()
    _G.dialog_component_callback_close = function() end
  else
    _G.dialog_component_callback_close()
    kulala.open()
    _G.dialog_component_callback_close = function()
      kulala_state_is_opened = false
      kulala_ui.close_kulala_buffer()
      _G.dialog_component_callback_close = function() end
    end
  end
  kulala_state_is_opened = not kulala_state_is_opened
end, { desc = "UI kulala toggle" })

map(ui_components_modes, "<A-Y>", function()
  if kulala_state_is_opened then
    kulala_ui.close_kulala_buffer()
    _G.dialog_component_callback_close = function() end
  else
    _G.dialog_component_callback_close()
    kulala_ui.open() -- this is key difference - it runs query on cursor
    _G.dialog_component_callback_close = function()
      kulala_state_is_opened = false
      kulala_ui.close_kulala_buffer()
      _G.dialog_component_callback_close = function() end
    end
  end
  kulala_state_is_opened = not kulala_state_is_opened
end, { desc = "UI kulala toggle with sending request" })

map("n", "<A-o>", function()
  if vim.g.state_oil_opened then
    oil.close()
    _G.dialog_component_callback_close = function() end
  else
    _G.dialog_component_callback_close()
    _G.dialog_component_callback_close = function()
      vim.g.state_oil_opened = false
      oil.close()
      _G.dialog_component_callback_close = function() end
    end
    vim.cmd "Neotree close"
    oil.open(nil, { preview = { vertical = true } })
  end
  vim.g.state_oil_opened = not vim.g.state_oil_opened
end, { desc = "UI oil toggle float browser" })

-- windows focus move
map(ui_components_modes, "<A-a>", "<C-W>h", { desc = "UI switch window left" })
map(ui_components_modes, "<A-d>", "<C-W>l", { desc = "UI switch window right" })
map(ui_components_modes, "<A-s>", "<C-W>j", { desc = "UI switch window down" })
map(ui_components_modes, "<A-w>", "<C-W>k", { desc = "UI switch window up" })
map("n", "+", "<C-W>3>", { desc = "UI window width increase" })
map("n", "_", "<C-W>3<", { desc = "UI window width decrease" })

map("n", "<leader>th", function()
  vim.cmd "Telescope colorscheme"
end, { desc = "Theme" })

-- neotree
local function workaround_neotree_focus(source, opts)
  pcall(function()
    dapui.close()
    local focus_command = vim.tbl_extend("error", {
      action = "focus", -- Focus NeoTree
      source = source,
      position = "left", -- Or "left", "float"
    }, opts)
    local reveal_command = vim.tbl_extend("error", {
      action = "reveal", -- Focus NeoTree
      source = source,
      position = "left", -- Or "left", "float"
    }, opts)
    neotree_command.execute(focus_command)
    vim.defer_fn(function()
      neotree_command.execute(reveal_command)
      neotree_command.execute(focus_command)
    end, 100)
  end)
end

map(ui_components_modes, "<A-e>", function()
  dapui.close()
  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)
  _G.dapui_callback_close()
  workaround_neotree_focus("filesystem", {
    reveal_file = file_path, -- Auto-highlight the file
    reveal_force_cwd = true, -- Ensure correct working dir
  })
end, { desc = "UI neotree files", silent = true })

map(ui_components_modes, "<A-l>", function()
  workaround_neotree_focus("document_symbols", {})
end, { desc = "UI neotree structure" })

_G.bottom_component_callback_close = function() end
--
-- special case for neotree only
_G.dapui_callback_close = function() end
local right_component_callback_close = function() end

vim.g.dapui_state_is_opened = false
-- toggle dapui
map(ui_components_modes, "<A-r>", function()
  if vim.g.dapui_state_is_opened then
    dapui.close()
    vim.cmd "Neotree reveal left source=filesystem"
  else
    vim.cmd "Neotree close"
    trouble.close()
    _G.bottom_component_callback_close()
    dapui.open()
    _G.bottom_component_callback_close = function()
      vim.g.dapui_state_is_opened = false
      dapui.close()
    end
    _G.dapui_callback_close = _G.bottom_component_callback_close
  end
  vim.g.dapui_state_is_opened = not vim.g.dapui_state_is_opened
end, { desc = "UI debug close view" })

-- spectre
vim.g.spectre_opened = false
map(ui_components_modes, "<A-q>", function()
  if vim.g.spectre_opened then
    spectre.close()
  else
    if is_normal_buffer() then
      right_component_callback_close()
      right_component_callback_close = function()
        vim.g.spectre_opened = false
        spectre.close()
      end
      spectre.open()
    end
  end
  vim.g.spectre_opened = not vim.g.spectre_opened
end, { desc = "UI Spectre toggle" })

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
end, { desc = "UI Test show summary" })

local neotest_output_opened = false
map(ui_components_modes, "<A-T>", function()
  if neotest_output_opened then
    neotest.output_panel.close()
  else
    _G.bottom_component_callback_close()
    _G.bottom_component_callback_close = function()
      neotest_output_opened = false
      neotest.output_panel.close()
    end
    neotest.output_panel.open()
  end
  neotest_output_opened = not neotest_output_opened
end, { desc = "UI Test show output" })

-- trouble plugin
-- "<cmd>Trouble diagnostics toggle focus=true<CR>"
map(ui_components_modes, "<A-p>", function()
  if trouble.is_open "lsp" then
    trouble.close "lsp"
  end
  if trouble.is_open "telescope" then
    trouble.close "telescope"
  end
  if trouble.is_open "telescope_files" then
    trouble.close "telescope_files"
  end
  if trouble.is_open "diagnostics" then
    trouble.close "diagnostics"
  else
    _G.bottom_component_callback_close()
    _G.bottom_component_callback_close = function()
      trouble.close "diagnostics"
    end
    trouble.open { mode = "diagnostics", focus = true }
  end
end, { desc = "UI trouble diagnostics" })

-- trouble plugin
-- "<cmd>Trouble diagnostics toggle focus=true<CR>"
map(ui_components_modes, "<A-i>", function()
  if trouble.is_open "diagnostics" then
    trouble.close "diagnostics"
  end
  if trouble.is_open "telescope" then
    trouble.close "telescope"
  end
  if trouble.is_open "telescope_files" then
    trouble.close "telescope_files"
  end
  if trouble.is_open "lsp" then
    trouble.close "lsp"
  else
    _G.bottom_component_callback_close()
    _G.bottom_component_callback_close = function()
      trouble.close "lsp"
    end
    trouble.close()
    trouble.open { mode = "lsp", focus = true }
  end
end, { desc = "UI trouble inspect" })

local git_blame_bufnr = 0
map("n", "<A-b>", function()
  if git_blame_bufnr == 0 then
    if is_normal_buffer() then
      gitsigns_async.create(0, function()
        gitsigns_blame.blame()
        git_blame_bufnr = vim.fn.bufnr()
      end)()
    end
  else
    vim.cmd(tostring(git_blame_bufnr) .. "bw")
    git_blame_bufnr = 0
  end
end, { desc = "UI git blame buffer" })
