local M = {}

---@param bufnr? integer
---@return boolean
local function skip_buffer(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  return vim.b[bufnr].minidiff_review == true or vim.b[bufnr].large_hunk_viewer == true
end

local start = vim.lsp.start
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.start(config, opts)
  opts = opts or {}
  if skip_buffer(opts.bufnr) then
    return nil
  end
  return start(config, opts)
end

local attach = vim.lsp.buf_attach_client
---@diagnostic disable-next-line: duplicate-set-field
function vim.lsp.buf_attach_client(bufnr, client_id)
  if skip_buffer(bufnr) then
    return false
  end
  return attach(bufnr, client_id)
end

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

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("LspNavigationMappingOverrides", { clear = true }),
  callback = function(ev)
    require("utils.clear_mappings_from_lsp").clear_mappings_from_lsp(ev.buf)
  end,
})

for _, lsp_name in ipairs(M.servers) do
  vim.lsp.enable(lsp_name)
end

return M
