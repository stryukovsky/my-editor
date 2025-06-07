require("cybu").setup {
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
