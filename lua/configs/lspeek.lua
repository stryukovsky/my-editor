local lspeek = require "lspeek"

lspeek.setup {
  window = {
    width = 90,
    height = 22,
    border = "rounded",
    win_opts = {
      signcolumn = "no",
      winbar = "",
      number = true,
    },
  },
  stack_limit = 5,
  -- One type is the common case; skip vim.ui.select and open the float.
  select_first = true,
  -- Close all previews when focus leaves a peek window for a non-peek window.
  is_fragile = true,
  keymaps = {
    close = "q",
    split = "s",
    vsplit = "v",
    enter = "<CR>",
    tab = "t",
    prev = "[",
    next = "]",
  },
}
