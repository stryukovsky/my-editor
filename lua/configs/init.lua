require("render-markdown").setup {
  file_types = { "markdown", "quarto" },
}

require("multicursor-nvim").setup()
require("kulala").setup {
  ui = {
    display_mode = "float"
  },
}

-- show nvdash when all buffers closed
vim.api.nvim_create_autocmd("BufDelete", {
  callback = function()
    local bufs = vim.t.bufs
    if #bufs == 1 and vim.api.nvim_buf_get_name(bufs[1]) == "" then
      vim.cmd "Nvdash"
    end
  end,
})

-- disable spell in terminal
-- vim.cmd("au TermOpen * setlocal nospell")
vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.cmd "setlocal nospell"
  end,
})

require("nvim-tree").setup(require "configs.nvimtree")

require "configs.tiny-code-action"
require "configs.oil"
require "configs.gomove"
require "configs.debuggers"
require "configs.dapui"
require "configs.lspsaga"
require "configs.diffview"
require "configs.substitute"
require "configs.neotest"
require "configs.trouble"

-- at the end, so all highlight rules can be applied
require "highlight"
