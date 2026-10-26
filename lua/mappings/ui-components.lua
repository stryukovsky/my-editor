---@diagnostic disable: duplicate-set-field
local map = require "mappings.map"
local neotest = require "neotest"
local trouble = require "trouble"
local oil = require "configs.oil"
local focus_neotree = require "utils.focus_neotree"
local grug_far = require "grug-far"
local close_telescope = require "mappings.close_telescope"
local ui_prevent_mess = require "utils.ui_prevent_mess"
local is_normal_buffer = require "utils.is_normal_buffer"
local notify = require "configs.notify"

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
      require("utils.project_files").open()
    end,
    desc = "UI telescope files",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-c>",
    command = function()
      require("telescope_pretty_picker").show_commits()
    end,
    desc = "UI telescope git commits",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-g>",
    command = function()
      require("telescope_pretty_picker").show_branches()
    end,
    desc = "UI telescope git branches",
  },
  {
    modes = ui_components_modes,
    shortcut = "<A-P>",
    command = function()
      -- Lists marked projects; [open] means a Kitty tab already exists (focus vs launch).
      require("configs.projects").picker_all()
    end,
    desc = "UI telescope projects",
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
    shortcut = "<A-F>",
    command = function()
      require("telescope_pretty_picker").show_search()
    end,
    desc = "UI telescope search in project",
  },
  {
    modes = { "v" },
    shortcut = "<A-F>",
    command = function()
      require("telescope_pretty_picker").show_visual_search()
    end,
    desc = "UI telescope search in project",
  },

  {
    modes = ui_components_modes,
    shortcut = "<A-y>",
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

map("n", "<leader>sa", function()
  ui_prevent_mess()
  vim.cmd "Telescope spell_suggest theme=get_cursor"
end, { desc = "Actions: spelling" })

local function telescope_is_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "TelescopePrompt" then
      return true
    end
  end
  return false
end

vim.g.last_opened_telescope = ""
_G.dialog_component_callback_close = function() end
for _, value in ipairs(telescope_components) do
  map(value.modes, value.shortcut, function()
    -- <leader> is Space; do not let <leader><leader> steal <Space> in a picker.
    if value.shortcut == "<leader><leader>" and telescope_is_open() then
      return
    end
    ui_prevent_mess()
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

map(ui_components_modes, "<A-z>", function()
  require("configs.zenmode").toggle_ui()
end, { desc = "UI zen mode" })

map("n", "<A-o>", function()
  ui_prevent_mess()
  oil.toggle()
end, { desc = "UI oil toggle file browser" })

-- windows focus move
local function prevent_ui_mess_then(command)
  return function()
    ui_prevent_mess()
    vim.cmd(command)
  end
end

map(ui_components_modes, "<A-a>", prevent_ui_mess_then "wincmd h", { desc = "UI switch window left" })
map(ui_components_modes, "<A-d>", prevent_ui_mess_then "wincmd l", { desc = "UI switch window right" })
map(ui_components_modes, "<A-s>", prevent_ui_mess_then "wincmd j", { desc = "UI switch window down" })
map(ui_components_modes, "<A-w>", prevent_ui_mess_then "wincmd k", { desc = "UI switch window up" })
map("n", "+", function()
  vim.cmd "wincmd 3>"
end, { desc = "UI window width increase" })
map("n", "_", function()
  vim.cmd "wincmd 3<"
end, { desc = "UI window width decrease" })

map("n", "<leader>th", function()
  ui_prevent_mess()
  vim.cmd "Telescope colorscheme"
end, { desc = "Theme" })

-- neotree
map(ui_components_modes, "<A-e>", function()
  ui_prevent_mess()
  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)
  local empty_file_path = file_path == ""
  local file_exists = false
  if not empty_file_path then
    local stat = vim.uv.fs_stat(file_path)
    if stat and stat.type == "file" then
      file_exists = true
    end
  end

  local params = {}
  if file_exists then
    params = {
      reveal_file = file_path, -- Auto-highlight the file
      reveal_force_cwd = true, -- Ensure correct working dir only if real existing on disk file was asked
    }
  end

  focus_neotree("filesystem", --[[ needs_reveal ==  ]] file_exists, params)
end, { desc = "UI neotree files", silent = true })

map(ui_components_modes, "<A-l>", function()
  ui_prevent_mess()
  focus_neotree("document_symbols", true, {})
end, { desc = "UI neotree structure" })

map(ui_components_modes, "<A-b>", function()
  ui_prevent_mess()
  focus_neotree("buffers", true, {})
end, { desc = "UI neotree buffers" })

map(ui_components_modes, "<A-k>", function()
  ui_prevent_mess()
  focus_neotree("git_status", false, {})
end, { desc = "UI neotree git status" })

_G.bottom_component_callback_close = function() end
--
-- special case for neotree only
local right_component_callback_close = function() end

local function close_grug_far()
  grug_far.hide_instance "far"
end

map(ui_components_modes, "<A-R>", function()
  ui_prevent_mess()
  if is_normal_buffer() then
    if _G.bottom_component_callback_close() == false then
      return
    end
    _G.bottom_component_callback_close = close_grug_far
    grug_far.toggle_instance { instanceName = "far", staticTitle = "Find and Replace" }
  end
end, { desc = "UI find and replace toggle" })

-- neotest
local neotest_summary_opened = false
map(ui_components_modes, "<A-t>", function()
  ui_prevent_mess()
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
  ui_prevent_mess()
  if neotest_output_opened then
    neotest.output_panel.close()
  else
    if _G.bottom_component_callback_close() == false then
      return
    end
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
  ui_prevent_mess()
  local review = require "configs.minidiff_review"
  if trouble.is_open "minidiff_review" or review.session() then
    if not review.finish_review() then
      return
    end
  end
  if trouble.is_open "lsp" then
    trouble.close "lsp"
  end
  if trouble.is_open "telescope" then
    trouble.close "telescope"
  end
  if trouble.is_open "telescope_files" then
    trouble.close "telescope_files"
  end
  if trouble.is_open "dap_breakpoints" then
    trouble.close "dap_breakpoints"
  end
  if trouble.is_open "diagnostics" then
    trouble.close "diagnostics"
  else
    if _G.bottom_component_callback_close() == false then
      return
    end
    _G.bottom_component_callback_close = function()
      trouble.close "diagnostics"
    end
    trouble.open { mode = "diagnostics", focus = true }
  end
end, { desc = "UI trouble diagnostics" })

-- trouble plugin
-- "<cmd>Trouble diagnostics toggle focus=true<CR>"
map(ui_components_modes, "<A-i>", function()
  ui_prevent_mess()
  local review = require "configs.minidiff_review"
  if trouble.is_open "minidiff_review" or review.session() then
    if not review.finish_review() then
      return
    end
  end
  if trouble.is_open "diagnostics" then
    trouble.close "diagnostics"
  end
  if trouble.is_open "telescope" then
    trouble.close "telescope"
  end
  if trouble.is_open "telescope_files" then
    trouble.close "telescope_files"
  end
  if trouble.is_open "dap_breakpoints" then
    trouble.close "dap_breakpoints"
  end
  if trouble.is_open "lsp" then
    trouble.close "lsp"
  else
    if _G.bottom_component_callback_close() == false then
      return
    end
    _G.bottom_component_callback_close = function()
      trouble.close "lsp"
    end
    trouble.close()
    trouble.open { mode = "lsp", focus = true }
  end
end, { desc = "UI trouble inspect" })
