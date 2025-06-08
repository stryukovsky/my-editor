local map = require "mappings.map"
local dapui = require "dapui"
local neotest = require "neotest"
local trouble = require "trouble"
local kulala = require "kulala"
local kulala_ui = require "kulala.ui"
local oil = require "oil"
local new_branch = require "ui.new_branch"
local commit = require "ui.commit"
local commit_amend = require "ui.commit_amend"
local gitsigns_async = require "gitsigns.async"
local gitsigns_blame = require "gitsigns.blame"
local avante = require "avante"

local ui_components_modes = { "n", "t", "v", "i" }

local telescope_components = {
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
  {
    modes = ui_components_modes,
    shortcut = "<A-l>",
    command = function()
      require("telescope.builtin").lsp_document_symbols {
        symbols = { "class", "field", "method", "module", "namespace" },
      }
    end,
    desc = "UI telescope previously opened files",
  },
}

map("n", "<leader>ga", "<cmd>Telescope spell_suggest theme=get_cursor<cr>", { desc = "Actions: spelling" })
map(
  "n",
  "<leader><leader>",
  "<cmd>Telescope buffers only_cwd=true theme=get_cursor previewer=false sort_lastused=true sort_mru=true<cr>",
  { desc = "UI telescope buffers" }
)

local last_opened_telescope = ""
local function close_telescope()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_get_option_value("filetype", { buf = buf }) == "TelescopePrompt" then
      vim.api.nvim_win_close(win, true)
      return true
    end
  end
  return false
end

local dialog_component_callback_close = function() end
for _, value in ipairs(telescope_components) do
  map(value.modes, value.shortcut, function()
    if close_telescope() then
      if last_opened_telescope ~= value.desc then
        value.command()
        last_opened_telescope = value.desc
      end
    else
      dialog_component_callback_close()
      value.command()
      last_opened_telescope = value.desc
      dialog_component_callback_close = function()
        close_telescope()
        last_opened_telescope = value.desc
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
end, { desc = "UI kulala toggle" })

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
end, { desc = "UI kulala toggle with sending request" })

local fileHistoryOpened = false
map(ui_components_modes, "<A-h>", function()
  if fileHistoryOpened then
    pcall(function()
      vim.cmd "tabc"
    end)
    dialog_component_callback_close = function() end
  else
    dialog_component_callback_close()
    pcall(function()
      vim.cmd "DiffviewFileHistory"
    end)
    dialog_component_callback_close = function()
      fileHistoryOpened = false
      vim.cmd "tabc"
    end
  end
  fileHistoryOpened = not fileHistoryOpened
end, { desc = "UI diffview file history" })

local diffViewOpened = false
map(ui_components_modes, "<A-k>", function()
  if diffViewOpened then
    vim.cmd "tabc"
    dialog_component_callback_close = function() end
  else
    dialog_component_callback_close()
    dialog_component_callback_close = function()
      diffViewOpened = false
      pcall(function()
        vim.cmd "tabc"
      end)
    end
    pcall(function()
      vim.cmd "DiffviewOpen"
    end)
  end
  diffViewOpened = not diffViewOpened
end, { desc = "UI diffview open merge tool" })

local oilOpened = false
map("n", "<A-o>", function()
  if oilOpened then
    oil.close()
    dialog_component_callback_close = function() end
  else
    dialog_component_callback_close()
    dialog_component_callback_close = function()
      oilOpened = false
      oil.close()
    end
    oil.open_float(nil, { preview = { vertical = true } })
  end
  oilOpened = not oilOpened
end, { desc = "UI oil toggle float browser" })

-- windows focus move
map(ui_components_modes, "<A-a>", "<C-W>h", { desc = "UI switch window left" })
map(ui_components_modes, "<A-d>", "<C-W>l", { desc = "UI switch window right" })
map(ui_components_modes, "<A-s>", "<C-W>j", { desc = "UI switch window down" })
map(ui_components_modes, "<A-w>", "<C-W>k", { desc = "UI switch window up" })
map("n", "+", "<C-W>3>", { desc = "UI window width increase" })
map("n", "_", "<C-W>3<", { desc = "UI window width decrease" })
map("n", "<leader>thd", function()
  vim.g.material_style = "lighter"
  vim.cmd "colorscheme material"
end, { desc = "Theme: day" })

map("n", "<leader>thn", function()
  vim.g.material_style = "deep ocean"
  vim.cmd "colorscheme material"
end, { desc = "Theme: night" })

-- focus nvimtree
map(ui_components_modes, "<A-e>", function()
  dapui.close()
  if vim.g.neotree_compat_first_file_picker then
    vim.cmd "Neotree focus current"
  else
    vim.cmd "Neotree focus left"
  end
end, { desc = "UI neotree focus window" })

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
end, { desc = "UI debug close view" })

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

local avante_state_opened = false
map(ui_components_modes, "<A-q>", function()
  if avante_state_opened then
    avante.close_sidebar()
  else
    right_component_callback_close()
    right_component_callback_close = function()
      avante_state_opened = false
      avante.close_sidebar()
    end
    avante.open_sidebar()
  end
  avante_state_opened = not avante_state_opened
end, { desc = "UI Avante toggle view" })

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
end, { desc = "UI Test show output" })

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
end, { desc = "UI trouble diagnostics" })

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
end, { desc = "UI trouble monitor definitions" })

map("n", "<leader>gb", function()
  new_branch()
end, { desc = "git new branch create&checkout" })

map("n", "<leader>gc", function()
  commit()
end, { desc = "git commit" })

map("n", "<leader>gC", function()
  commit_amend()
end, { desc = "git commit amend" })

local git_blame_bufnr = 0
map("n", "<A-b>", function()
  if git_blame_bufnr == 0 then
    if vim.api.nvim_get_option_value("buftype", { buf = vim.fn.bufnr() }) == "" then
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
