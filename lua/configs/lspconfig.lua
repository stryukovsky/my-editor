
dofile(vim.g.base46_cache .. "lsp")
require("nvchad.lsp").diagnostic_config()

local lsp_with_default_conf = { "html", "cssls", "ts_ls", "lua_ls", "sqls", "jsonls", "bashls", "solidity", "pyright", "gopls", "jdtls"}

require("java").setup()
for _, lsp_name in ipairs(lsp_with_default_conf) do
    vim.lsp.enable(lsp_name)
end

