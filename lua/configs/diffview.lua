---@diagnostic disable: duplicate-set-field
local diffview_actions = require "diffview.actions"
local function do_nothing() end

local function open_file_from_diffview()
  vim.g.diffViewOpened = false
  vim.g.fileHistoryOpened = false
  _G.dialog_component_callback_close = function() end
  diffview_actions.goto_file_edit()
  -- legacy way to do the same stuff
  -- local opened_file = vim.fn.expand "%"
  -- -- file is opened in new tab
  -- -- so we need to close tab with opened file and also tab with diffview
  -- vim.cmd "2tabc"
  -- vim.cmd("edit " .. opened_file)
end

local function add(array1, array2)
  local merged = vim.deepcopy(array1)

  for _, value in ipairs(array2) do
    table.insert(merged, value)
  end

  return merged
end

local function override_select_entry()
  diffview_actions.select_entry()
  require("diffview").emit "select_entry"
  require("diffview").emit "focus_entry"
end

local mocks = {
  { "n", "<A-q>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-r>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-t>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-y>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-u>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-i>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-o>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-p>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-f>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-F>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-g>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-G>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-H>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-h>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-k>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-K>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-l>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-L>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-z>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-Z>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-x>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-X>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-c>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-C>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-V>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-v>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-b>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-B>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-N>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-n>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-m>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-M>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-,>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-.>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-<>", do_nothing, { desc = "do nothing" } },
  { "n", "<A->>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-/>", do_nothing, { desc = "do nothing" } },
  { "n", "<A-?>", do_nothing, { desc = "do nothing" } },
}

local file_panel_keymaps = {
  { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "h", diffview_actions.close_fold, { desc = "Collapse fold" } },
  { "n", "l", override_select_entry, { desc = "Open the diff for the selected entry" } },
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
}
local file_history_keymaps = {
  { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
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
}

local diff_keymaps = {

  { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
}
local views_keymaps = {
  { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
  { "n", "h", diffview_actions.close_fold, { desc = "Collapse fold" } },
  -- { "n", "l", diffview_actions.select_entry, { desc = "Open the diff for the selected entry" } },
}

require("diffview").setup {
  hooks = {
    diff_buf_win_enter = function(bufnr, winid, ctx)
      vim.g.diffViewOpened = true
      vim.g.fileHistoryOpened = true

      -- 1. Disable text wrapping if you don't want lines wrapped
      vim.wo[winid].wrap = false

      -- 2. Prevent Tree-sitter/Neovim from closing your folds automatically
      vim.wo[winid].foldenable = false

      -- Alternative to step 2: If you WANT folds but want them completely open
      -- by default instead of hidden, comment out line 7 and uncomment below:
      -- vim.wo[winid].foldlevel = 99
    end,
  },
  view = {
    default = {
      -- layout = "diff1_plain",
      layout = "diff2_horizontal",
      -- layout = "diff2_vertical",
      disable_diagnostics = true,
      winbar_info = false,
    },
    merge_tool = {
      -- layout = "diff3_mixed",
      layout = "diff1_plain",
      disable_diagnostics = true,
      winbar_info = false,
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
    view = add(views_keymaps, mocks),
    diff1 = add(diff_keymaps, mocks),
    diff2 = add(diff_keymaps, mocks),
    diff3 = add(diff_keymaps, mocks),
    file_history_panel = add(file_history_keymaps, mocks),
    file_panel = add(file_panel_keymaps, mocks),
  },
}
