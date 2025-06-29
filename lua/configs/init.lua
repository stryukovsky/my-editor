require "configs.telescope"
require("render-markdown").setup()
require("multicursor-nvim").setup()
require("Comment").setup()
require("todo-comments").setup()

require "configs.barbar"
require "configs.kulala"
require "configs.tiny-code-action"
require "configs.oil"
require "configs.gomove"
require "configs.debuggers"
require "configs.dapui"
require "configs.diffview"
require "configs.neotest"
require "configs.trouble"
require "configs.lualine"
-- require "configs.luasnip"
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
require "configs.grapple"
require "configs.langmapper"
require "configs.siblingswap"
require "configs.nvimdap-virtual-text"
require "configs.noice"

-- require("codecompanion").setup {
--   strategies = {
--     chat = {
--       adapter = "deepseekr1",
--     },
--     inline = {
--       adapter = "deepseekr1",
--     },
--     cmd = {
--       adapter = "deepseekr1",
--     },
--   },
--   adapters = {
--     deepseekr1 = function()
--       return require("codecompanion.adapters").extend("ollama", {
--         name = "deepseekr1", -- Give this adapter a different name to differentiate it from the default ollama adapter
--         schema = {
--           model = {
--             default = "deepseek-r1:latest",
--           },
--           num_ctx = {
--             default = 16384,
--           },
--           num_predict = {
--             default = -1,
--           },
--         },
--       })
--     end,
--   },
-- }

require "configs.blink"
-- at the end, so all highlight rules can be applied
require "configs.theme"
require "highlight"
