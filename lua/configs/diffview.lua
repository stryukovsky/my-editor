---@diagnostic disable: duplicate-set-field
local diffview_actions = require "diffview.actions"
local function open_file_from_diffview()
  vim.print("LOL")
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
require("diffview").setup {
  view = {
    merge_tool = {
      -- layout = "diff3_mixed",
      layout = "diff1_plain",
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
      { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      {
        "n",
        "<A-k>",
        function()
          if vim.g.diffViewOpened then
            vim.g.diffViewOpened = false
          elseif vim.g.fileHistoryOpened then
            vim.g.fileHistoryOpened = false
          else
            vim.print "WARNING: Bad state of diffview toggling ui-components"
          end
          vim.cmd "tabc"
        end,
        { desc = "Close diffview ", silent = true },
      },
      {
        "n",
        "<A-h>",
        function()
          if vim.g.diffViewOpened then
            vim.g.diffViewOpened = false
          elseif vim.g.fileHistoryOpened then
            vim.g.fileHistoryOpened = false
          else
            vim.print "WARNING: Bad state of diffview toggling ui-components"
          end
          vim.cmd "tabc"
        end,
        { desc = "Close diffview ", silent = true },
      },
      { "n", "h", diffview_actions.close_fold, { desc = "Collapse fold" } },
      { "n", "l", diffview_actions.select_entry, { desc = "Open the diff for the selected entry" } },
    },
    diff1 = {

      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
    },
    diff2 = {

      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
    },
    diff3 = {

      { "n", "<A-e>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-l>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
      { "n", "<A-b>", diffview_actions.focus_files, { desc = "UI Focus Files" } },
    },
    file_history_panel = {
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
    },
    file_panel = {
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
    },
  }
}
