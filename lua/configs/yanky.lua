local yanky = require "yanky"
local mapping = require "yanky.telescope.mapping"
local utils = require "yanky.utils"

yanky.setup {
  ring = {
    history_length = 100,
    storage = "memory",
  },
  preserve_cursor_position = {
    enabled = true,
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
          p = mapping.put "P",
          d = mapping.delete(),
          r = mapping.set_register(utils.get_default_register()),
        },
      },
    },
  },
  highlight = {
    on_put = false,
    on_yank = false,
    timer = 100
  },
}

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", {} --[[ { clear = true } ]]),
  callback = function()
    local ok, mc = pcall(require, "multicursor-nvim")
    if ok and mc.hasCursors() then
      -- Skip highlight when multicursor is active
      return
    end
    vim.highlight.on_yank {
      higroup = "IncSearch",
      timeout = 600,
    }
  end,
})
