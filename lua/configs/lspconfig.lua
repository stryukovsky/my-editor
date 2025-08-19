local lsp_with_default_conf =
  { "html", "cssls", "ts_ls", "lua_ls", "sqls", "jsonls", "bashls", "pyright", "gopls", "clangd", "solidity_ls_nomicfoundation" }

-- vim.lsp.config("*", {})
for _, lsp_name in ipairs(lsp_with_default_conf) do
    vim.lsp.enable(lsp_name)
end
