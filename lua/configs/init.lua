require "configs.telescope"
require("multicursor-nvim").setup()
require("Comment").setup()
require("todo-comments").setup()
require("log-highlight").setup {}

local termux_version = os.getenv "TERMUX_VERSION"

if not termux_version then
  require "configs.yanky"
end

require "configs.telescope_pretty_git"
require "configs.marks"
require "configs.barbar"
require "configs.scope"
require "configs.projects"
require "configs.treesitter"
require "configs.oil"
require "configs.luasnip"
require "configs.gomove"
require "configs.minidiff"
require "configs.neotest"
require "configs.trouble"
require "configs.lualine"
require "configs.render-markdown"
require "lspconfig"
require "configs.lspconfig"
require "configs.lsp_controls"
require "configs.lspeek"
require "configs.diagnostic"
require "configs.trouble"
require "configs.text-case"
require "configs.illuminate"
require "configs.neotree"
require "configs.neogit-setup"
require "configs.dashboard"

-- Initialize periodic git fetch
require("configs.periodic-git-fetch").setup()
require "configs.fidget"
require "configs.langmapper"
require "configs.siblingswap"
require "configs.blink"
require "configs.minuet-ai"
require "configs.codecompanion"
require "configs.grapple"
require "configs.aidviser"
require "configs.whichkey"
require "configs.grug-far"
require "configs.treesj"
require "configs.debuggers"
require "configs.debug_output"
require "configs.flash"
require "configs.searchbox"
require "configs.hlslens"
require "configs.gitconflict"
require "configs.surround"
require "configs.rainbow_delimiters"
-- at the end, so all highlight rules can be applied
require "configs.material-theme"
require "highlight"
require "configs.bigfiles"
require "configs.templates"
require "configs.statuscolumn"
require "configs.zenmode"
require "configs.todotxt"
require "configs.macros-recorder"
require "configs.csv"
require("configs.input").setup()
