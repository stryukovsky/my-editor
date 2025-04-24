dofile(vim.g.base46_cache .. "lsp")
require("nvchad.lsp").diagnostic_config()

local lsp_with_default_conf =
  { "html", "cssls", "ts_ls", "lua_ls", "sqls", "jsonls", "bashls", "solidity_ls", "pyright", "gopls", "jdtls" }

vim.lsp.config("solidity_ls", {
  cmd = { "vscode-solidity-server", "--stdio" },
  filetypes = { "solidity" },
  root_markers = {
    "hardhat.config.js",
    "hardhat.config.ts",
    "foundry.toml",
    "remappings.txt",
    "truffle.js",
    "truffle-config.js",
    "ape-config.yaml",
    ".git",
    "package.json",
  },
  settings = {
    solidity = {
      compileUsingRemoteVersion = "latest",
      defaultCompiler = "remote",
      enabledAsYouTypeCompilationErrorCheck = true,
    },
  },
})

require("java").setup()
for _, lsp_name in ipairs(lsp_with_default_conf) do
  vim.schedule(function()
    vim.lsp.enable(lsp_name)
  end)
end
