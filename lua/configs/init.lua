require("render-markdown").setup {
  file_types = { "markdown", "quarto" },
}

require("multicursor-nvim").setup()
require("kulala").setup(require "configs.kulala")
require("nvim-tree").setup(require "configs.nvimtree")
require("Comment").setup()
require("todo-comments").setup()

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
require "configs.lualine"
require "configs.theme"
require "lspconfig"
require "configs.lspconfig"


-- at the end, so all highlight rules can be applied
require "highlight"
