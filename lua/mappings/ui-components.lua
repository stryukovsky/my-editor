local map = require "mappings.map"
local dapui = require "dapui"
local neotest = require "neotest"
local trouble = require "trouble"
local kulala = require "kulala"
local kulala_ui = require "kulala.ui"
local oil = require "oil"
local gitsigns_async = require "gitsigns.async"
local gitsigns_blame = require "gitsigns.actions.blame"
local diffview_actions = require "diffview.actions"
local neotree_command = require "neo-tree.command"

local ui_components_modes = { "n", "t", "v", "i" }

local telescope_components = {
  {
    modes = ui_components_modes,
    shortcut = "<A-m>",
    command = function()
      vim.cmd "Telescope marks"
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
      local keymap = require "mappings.telescope.git_branches_actions"
      local descriptions = {
        ["<cr>"] = "Switch to branch",
        d = "Diff current branch with selected one",
        x = "delete branch locally",
        m = "merge branch into current one",
        r = "rebase current branch onto selected one",
      }

      local lines = {}
      for key, _ in pairs(keymap) do
        local desc = descriptions[key] or "Unknown action"
        table.insert(lines, string.format("%s: %s", key, desc))
      end

      -- Sort the lines for consistent output (optional)
      table.sort(lines)

      local description = "Normal mode actions: \n" .. table.concat(lines, "\n")
      vim.print(description)
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
  -- if vim.g.neotree_compat_idle then
  --   return
  -- end
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
    local result = pcall(function()
      vim.cmd "tabc"
    end)
    if not result then
      -- additionally invert flag so before this line it is false,
      diffViewOpened = not diffViewOpened
      -- after it is true
      -- at the end of this function, this flag will be inversed again
    end
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

local function open_file_from_diffview()
  diffViewOpened = false
  fileHistoryOpened = false
  diffview_actions.goto_file_tab()
  local opened_file = vim.fn.expand "%"
  -- file is opened in new tab
  -- so we need to close tab with opened file and also tab with diffview
  vim.cmd "2tabc"
  vim.cmd("edit " .. opened_file)
end

require("diffview").setup {
  view = {
    merge_tool = {
      layout = "diff3_mixed",
      disable_diagnostics = true,
      winbar_info = true,
    },
  },
  file_history_panel = {
    log_options = {
      git = {
        single_file = {
          diff_merges = "first-parent",
          follow = true,
        },
        multi_file = {
          diff_merges = "first-parent",
        },
      },
    },
    win_config = {
      position = "bottom",
      height = 16,
      win_opts = {},
    },
  },

  keymaps = {
    view = {
      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      {
        "n",
        "<A-k>",
        function()
          vim.cmd "tabc"
        end,
        { desc = "Close diffview " },
      },
      {
        "n",
        "<A-h>",
        function()
          vim.cmd "tabc"
        end,
        { desc = "Close diffview " },
      },
      { "n", "h", diffview_actions.close_fold, { desc = "Collapse fold" } },
      { "n", "l", diffview_actions.select_entry, { desc = "Open the diff for the selected entry" } },
    },
    diff2 = {

      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
    },
    diff3 = {

      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
    },
    file_history_panel = {
      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "h", diffview_actions.close_fold, { desc = "Collapse fold" } },
      { "n", "l", diffview_actions.select_entry, { desc = "Open the diff for the selected entry" } },
      {
        "n",
        "o",
        open_file_from_diffview,
        { desc = "Go to file" },
      },
      {
        "n",
        "O",
        open_file_from_diffview,
        { desc = "Go to file" },
      },
    },
    file_panel = {
      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "h", diffview_actions.close_fold, { desc = "Collapse fold" } },
      { "n", "l", diffview_actions.select_entry, { desc = "Open the diff for the selected entry" } },
      {
        "n",
        "o",
        open_file_from_diffview,
        { desc = "Go to file" },
      },
      {
        "n",
        "O",
        open_file_from_diffview,
        { desc = "Go to file" },
      },
    },
  },
}

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

map("n", "<leader>th", function()
  vim.cmd "Telescope colorscheme"
end, { desc = "Theme" })

-- neotree
local function workaround_neotree_focus(source, opts)
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
  vim.defer_fn(function ()
    neotree_command.execute(reveal_command)
    neotree_command.execute(focus_command)
  end, 100)
end

map(ui_components_modes, "<A-e>", function()
  dapui.close()
  local current_buf = vim.api.nvim_get_current_buf()
  local file_path = vim.api.nvim_buf_get_name(current_buf)
  workaround_neotree_focus("filesystem", {
    reveal_file = file_path, -- Auto-highlight the file
    reveal_force_cwd = true, -- Ensure correct working dir
  })
end, { desc = "UI neotree files" })

map(ui_components_modes, "<A-b>", function()
  workaround_neotree_focus("buffers", {})
end, { desc = "UI neotree buffers" })

map(ui_components_modes, "<A-l>", function()
  workaround_neotree_focus("document_symbols", {})
end, { desc = "UI neotree structure" })

local bottom_component_callback_close = function() end
local right_component_callback_close = function() end

local dapui_state_is_opened = false
-- toggle dapui
map(ui_components_modes, "<A-r>", function()
  if dapui_state_is_opened then
    dapui.close()
    vim.cmd "Neotree reveal left source=filesystem"
  else
    vim.cmd "Neotree close"
    trouble.close()
    bottom_component_callback_close()
    dapui.open()
    bottom_component_callback_close = function()
      dapui_state_is_opened = false
      dapui.close()
    end
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
    bottom_component_callback_close()
    bottom_component_callback_close = function()
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
    bottom_component_callback_close()
    bottom_component_callback_close = function()
      trouble.close "lsp"
    end
    trouble.close()
    trouble.open { mode = "lsp", focus = true }
  end
end, { desc = "UI trouble inspect" })

local git_blame_bufnr = 0
map("n", "<A-B>", function()
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
