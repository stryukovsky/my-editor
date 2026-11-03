local zen = require "integrations.zen"

zen.setup {
  window = {
    backdrop = 0.90,
    width = 110,
    height = 1,
    options = {
      number = false,
      relativenumber = false,
      cursorcolumn = false,
      list = false,
    },
  },
}

return zen
