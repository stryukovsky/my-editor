require("cybu").setup {
  position = {
    relative_to = "win",          -- win, editor, cursor
    anchor = "topcenter",         -- topleft, topcenter, topright,
                                    -- centerleft, center, centerright,
                                    -- bottomleft, bottomcenter, bottomright
    vertical_offset = 10,         -- vertical offset from anchor in lines
    horizontal_offset = 0,        -- vertical offset from anchor in columns
    max_win_height = 50,           -- height of cybu window in lines
    max_win_width = 0.5,          -- integer for absolute in columns
                                    -- float for relative to win/editor width
  },
  behavior = { -- set behavior for different modes
    mode = {
      default = {
        switch = "immediate", -- immediate, on_close
        view = "paging", -- paging, rolling
      },
      last_used = {
        switch = "immediate", -- immediate, on_close
        view = "paging", -- paging, rolling
      },
      auto = {
        view = "paging", -- paging, rolling
      },
    },
    show_on_autocmd = false, -- event to trigger cybu (eg. "BufEnter")
  },
  display_time = 800, -- time the cybu window is displayed
}
