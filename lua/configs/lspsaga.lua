local lspsaga = require "lspsaga"

lspsaga.setup {
  symbol_in_winbar = {
    enable = false,
  },
  finder = {
    max_height = 0.6,
    keys = {
      -- close = "<Esc>",
      quit = "<Esc>",
      toggle_or_open = "<cr>",
      shuttle = "<Tab>",
    },
  },
  callhierarchy = {
    keys = {
      close = "<Esc>",
      toggle_or_req = "<cr>",
      shuttle = "<Tab>",
    },
  },
  lightbulb = {
    sign = false,
  },
}
