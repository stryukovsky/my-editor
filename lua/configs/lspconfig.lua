-- load defaults i.e lua_lsp
require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- EXAMPLE
local servers = { "html", "cssls" }
local nvlsp = require "nvchad.configs.lspconfig"
local util = require "lspconfig/util"
-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvlsp.on_attach,
    on_init = nvlsp.on_init,
    capabilities = nvlsp.capabilities,
  }
end

lspconfig.ts_ls.setup {
  on_attach = nvlsp.on_attach,
  on_init = nvlsp.on_init,
  capabilities = nvlsp.capabilities,
}

lspconfig.gopls.setup {
  on_attach = nvlsp.on_attach,
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

lspconfig.golangci_lint_ls.setup {
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go", "gomod", "gowork", "gopattern" },
  root_dir = util.root_pattern("go.mod", "go.work"),
  init_options = {
    command = { "golangci-lint", "run", "--out-format", "json", "--issues-exit-code=1" },
  },
  settings = {
    gopls = {
      completeUnimported = true,
    },
  },
}

lspconfig.sqls.setup{}
lspconfig.jsonls.setup{}
lspconfig.rust_analyzer.setup {}

require("java").setup()
lspconfig.jdtls.setup {}
lspconfig.bashls.setup{}
lspconfig.solidity_ls_nomicfoundation.setup{}
