require "configs.telescope"
require("multicursor-nvim").setup()
require("Comment").setup()
require("todo-comments").setup()
require("log-highlight").setup {}

local termux_version = os.getenv "TERMUX_VERSION"

if not termux_version then
  require "configs.yanky"
end

require "configs.marks"
require "configs.barbar"
require "configs.treesitter"
require "configs.kulala"
require "configs.oil"
require "configs.gomove"
require "configs.gitsigns"
require "configs.neotest"
require "configs.trouble"
require "configs.lualine"
require "configs.render-markdown"
require "lspconfig"
require "configs.lspconfig"
require "configs.diagnostic"
require "configs.trouble"
require "configs.text-case"
require "configs.illuminate"
require "configs.neotree"
require "configs.neogit-setup"
require "configs.periodic-git-fetch"
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
require "configs.spectre"
require "configs.treesj"
require "configs.debuggers"
require "configs.flash"
require "configs.gitconflict"
require "configs.surround"
require "configs.rainbow_delimiters"
-- at the end, so all highlight rules can be applied
require "configs.material-theme"
require "highlight"
