local lsp_with_default_conf = {
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

for _, lsp_name in ipairs(lsp_with_default_conf) do
  vim.lsp.enable(lsp_name)
end
