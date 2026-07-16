return {
  highlights = {
    -- char_insert = "#22bb22", -- Character-level insertions (nil = auto-derive)
    -- char_delete = "#ffaabb", -- Character-level deletions (nil = auto-derive)
  },
  diff = {
    layout = "inline",
  },
  explorer = {
      focus_on_select = true,
      view_mode = "tree",
  },
  keymaps = {
    view = {
      quit = "q", -- Close diff tab
      toggle_explorer = "<leader>b", -- Toggle explorer visibility (explorer mode only)
      focus_explorer = "<A-e>", -- Focus explorer panel (explorer mode only)
      next_hunk = "]g", -- Jump to next change
      prev_hunk = "[g", -- Jump to previous change
      next_file = "]f", -- Next file in explorer/history mode
      prev_file = "[f", -- Previous file in explorer/history mode
      open_in_prev_tab = "o", -- Open current buffer in previous tab (or create one before)
      close_on_open_in_prev_tab = true, -- Close codediff tab after gf opens file in previous tab
      -- stage_hunk = "<leader>gs", -- Stage hunk under cursor to git index
      unstage_hunk = "<leader>gu", -- Unstage hunk under cursor from git index
      discard_hunk = "<leader>gr", -- Discard hunk under cursor (working tree only)
      hunk_textobject = "ih", -- Textobject for hunk (vih to select, yih to yank, etc.)
      show_help = "g?", -- Show floating window with available keymaps
      align_move = "gm", -- Temporarily align moved code blocks across panes
      toggle_layout = "t", -- Toggle between side-by-side and inline layout
      toggle_compact = "gc", -- Toggle compact mode (fold unchanged regions)
      toggle_stage = "s",
    },
    explorer = {
      select = "<CR>",
    },
  },
}
