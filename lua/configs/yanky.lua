local yanky = require "yanky"
local mapping = require "yanky.telescope.mapping"
local utils = require "yanky.utils"

yanky.setup {
  ring = {
    history_length = 100,
    storage = "memory",
  },
  picker = {
    telescope = {
      mappings = {
        default = mapping.put "P",
        i = {
          ["<c-g>"] = mapping.put "p",
          ["<c-k>"] = mapping.put "P",
          ["<c-x>"] = mapping.delete(),
          ["<c-r>"] = mapping.set_register(utils.get_default_register()),
        },
        n = {
          p = mapping.put "p",
          P = mapping.put "P",
          d = mapping.delete(),
          r = mapping.set_register(utils.get_default_register()),
        },
      },
    },
    highlight = {
      on_put = true,
      on_yank = true,
      timer = 50,
    },
  },
}
