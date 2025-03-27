local lspsaga = require "lspsaga"

lspsaga.setup {
  finder = {
    max_height = 0.6,
    keys = {
      close = "<Esc>",
      toggle_or_open = "<cr>",
      shuttle = "<Tab>",
    },
  },
  definition = {
    max_height = 0.6,
    keys = {
      close = "<Esc>",
      edit = "<cr>",
    },
  },
  callhierarchy = {
    keys = {
      close = "<Esc>",
      toggle_or_req = "<cr>",
      shuttle = "<Tab>",
    },
  },
}
