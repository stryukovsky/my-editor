require "nvchad.options"

-- add yours here!

local o = vim.o
o.cursorlineopt = "both" -- to enable cursorline!
o.spelllang = "programming,en,ru"
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
vim.api.nvim_create_autocmd("BufWinEnter", {
  callback = function()
    o.spell = true
    vim.o.spelloptions = "camel,noplainbuffer"
  end,
})
