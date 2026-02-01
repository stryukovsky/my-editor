require "configs.telescope"
require("multicursor-nvim").setup()
require("Comment").setup()
require("todo-comments").setup()
require("log-highlight").setup {}

require "configs.yanky"
require "configs.marks"
require "configs.barbar"
require "configs.treesitter"
require "configs.kulala"
require "configs.oil"
require "configs.gomove"
require "configs.dapui"
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
require "configs.dashboard"
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
-- at the end, so all highlight rules can be applied
require "configs.material-theme"
require "highlight"

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("highlight-yank", {} --[[ { clear = true } ]]),
  callback = function()
    local mc = require "multicursor-nvim"
    mc.action(function(ctx)
      local cursors = ctx:getCursors()
      -- only if one cursor (i.e. no multicursor)
      -- there will be highlight on yank
      if #cursors == 1 then
        vim.highlight.on_yank {
          higroup = "IncSearch",
          timeout = 600,
        }
      end
    end)

    -- Clear highlights after 1 second
  end,
})
