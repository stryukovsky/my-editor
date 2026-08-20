local M = {}

M.servers = {
  "html",
  "cssls",
  "ts_ls",
  "lua_ls",
  "sqls",
  "bashls",
  "basedpyright",
  "gopls",
  "clangd",
  "solidity_ls",
  "texlab",
  "jdtls",
  "move_analyzer",
}

vim.lsp.config("solidity_ls", {
  settings = {
    solidity = {
      enabledSolhint = false,
      enabledSolium = false,
    },
  },
})

local pattern_for_jars_for_java_debugger = "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
local bundles = vim.fn.glob(vim.fn.stdpath "data" .. pattern_for_jars_for_java_debugger, true, true)

vim.lsp.config("jdtls", {
  settings = {
    java = {
      -- Custom eclipse.jdt.ls options go here
    },
  },
  init_options = {
    bundles = bundles,
  },
})

for _, lsp_name in ipairs(M.servers) do
  vim.lsp.enable(lsp_name)
end

return M
