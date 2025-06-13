require("configs.telescope")
require("render-markdown").setup()
require("multicursor-nvim").setup()
require("Comment").setup()
require("todo-comments").setup()

require("configs.barbar")
require("configs.kulala")
require "configs.tiny-code-action"
require "configs.oil"
require "configs.gomove"
require "configs.debuggers"
require "configs.dapui"
require "configs.lspsaga"
require "configs.diffview"
require "configs.neotest"
require "configs.trouble"
require "configs.lualine"
require "configs.nvimcmp"
require "configs.luasnip"
require "lspconfig"
require "configs.lspconfig"
require "configs.diagnostic"
require "configs.trouble"
require "configs.autosave"
require "configs.text-case"
require "configs.illuminate"
require "configs.neotree"
require "configs.neogit-setup"
require "configs.dashboard"
require "configs.fidget"
require "configs.grapple"
require "configs.langmapper"

-- at the end, so all highlight rules can be applied
require "configs.theme"
require "highlight"
