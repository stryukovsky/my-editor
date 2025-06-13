local lsp_with_default_conf =
  { "html", "cssls", "ts_ls", "lua_ls", "sqls", "jsonls", "bashls", "solidity_ls", "pyright", "gopls", "clangd" }

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

-- vim.lsp.config("*", {})
for _, lsp_name in ipairs(lsp_with_default_conf) do
    vim.lsp.enable(lsp_name)
end
