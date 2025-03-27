-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- EXAMPLE
local lsp_with_default_conf =
  { "html", "cssls", "ts_ls", "lua_ls", "sqls", "jsonls", "rust_analyzer", "bashls", "solidity_ls_nomicfoundation" }
local nvlsp = require "nvchad.configs.lspconfig"

-- default nvchad mappings are overridden
local override_on_attach = require "mappings.lspconfig"

local util = require "lspconfig/util"
-- lsps with default config
for _, lsp in ipairs(lsp_with_default_conf) do
  lspconfig[lsp].setup {
    on_attach = override_on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

lspconfig.gopls.setup {
  on_attach = override_on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gopattern" },
  root_dir = util.root_pattern("go.mod", "go.work"),
  settings = {
    gopls = {
      completeUnimported = true,
    },
  },
}

require("java").setup()
lspconfig.jdtls.setup {
  on_attach = override_on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}
