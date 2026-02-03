local neogit = require "neogit"

neogit.setup {
  graph_style = "unicode",
  kind = "split",
  -- Floating window style
  floating = {
    relative = "editor",
    width = 0.8,
    height = 0.7,
    style = "minimal",
    border = "rounded",
  },
  -- Disable line numbers
  disable_line_numbers = true,
  -- Disable relative line numbers
  -- The time after which an output console is shown for slow running commands
  disable_relative_line_numbers = true,
  console_timeout = 10000,
  -- Automatically show console if a command takes more than console_timeout milliseconds
  auto_show_console = false,
  -- Automatically close the console if the process exits with a 0 (success) status
  auto_close_console = true,
  commit_editor = {
    kind = "split",
    show_staged_diff = true,
    -- Accepted values:
    -- "split" to show the staged diff below the commit editor
    -- "vsplit" to show it to the right
    -- "split_above" Like :top split
    -- "vsplit_left" like :vsplit, but open to the left
    -- "auto" "vsplit" if window would have 80 cols, otherwise "split"
    staged_diff_split_kind = "split",
    spell_check = true,
  },
  commit_select_view = {
    kind = "floating",
  },
  commit_view = {
    kind = "split",
    verify_commit = vim.fn.executable "gpg" == 1, -- Can be set to true or false, otherwise we try to find the binary
  },
  log_view = {
    kind = "split",
  },
  rebase_editor = {
    kind = "floating",
  },
  reflog_view = {
    kind = "floating",
  },
  merge_editor = {
    kind = "floating",
  },
  preview_buffer = {
    kind = "floating",
  },
  popup = {
    kind = "floating",
  },
  stash = {
    kind = "floating",
  },
  refs_view = {
    kind = "floating",
  },
  -- Each Integration is auto-detected through plugin presence, however, it can be disabled by setting to `false`
  integrations = {
    -- If enabled, use telescope for menu selection rather than vim.ui.select.
    -- Allows multi-select and some things that vim.ui.select doesn't.
    telescope = true,
    -- Neogit only provides inline diffs. If you want a more traditional way to look at diffs, you can use `diffview`.
    -- The diffview integration enables the diff popup.
    --
    -- Requires you to have `sindrets/diffview.nvim` installed.
    diffview = true,

    -- If enabled, uses fzf-lua for menu selection. If the telescope integration
    -- is also selected then telescope is used instead
    -- Requires you to have `ibhagwan/fzf-lua` installed.
    fzf_lua = false,

    -- If enabled, uses mini.pick for menu selection. If the telescope integration
    -- is also selected then telescope is used instead
    -- Requires you to have `echasnovski/mini.pick` installed.
    mini_pick = false,

    -- If enabled, uses snacks.picker for menu selection. If the telescope integration
    -- is also selected then telescope is used instead
    -- Requires you to have `folke/snacks.nvim` installed.
    snacks = false,
  },
  mappings = {
    status = {
      ["<Esc>"] = "Close",
      ["<Tab>"] = function() end,
      ["o"] = "GoToFile",
      ["[g"] = "GoToPreviousHunkHeader",
      ["]g"] = "GoToNextHunkHeader",
    },

    commit_editor = {
      ["q"] = "Close",
      ["<Esc>"] = "Close",
      ["<c-c><c-c>"] = "Submit",
      ["<c-c><c-k>"] = "Abort",
      ["<m-p>"] = "PrevMessage",
      ["<m-n>"] = "NextMessage",
      ["<m-r>"] = "ResetMessage",
    },
  },
}
