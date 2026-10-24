local M = {}

---@param bufnr? integer
---@return boolean
local function skip_buffer(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if vim.b[bufnr].minidiff_review == true or vim.b[bufnr].large_hunk_viewer == true then
    return true
  end
  if vim.b[bufnr].lsp_disabled == true then
    return true
  end
  local ok, bigfiles = pcall(require, "configs.bigfiles")
  return ok and bigfiles.is_skipping(bufnr)
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
  "forge",
  "texlab",
  "jdtls",
  "move_analyzer",
  "jsonls",
}

vim.lsp.config("clangd", {
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
})

vim.lsp.config("gopls", {
  filetypes = { "go", "gomod", "gowork" },
})

vim.lsp.config("forge", {
  cmd = { "forge", "lsp", "--stdio" },
  filetypes = { "solidity" },
  root_markers = { "foundry.toml", ".git" },
})

local pattern_for_jars_for_java_debugger = "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
local bundles = vim.fn.glob(vim.fn.stdpath "data" .. pattern_for_jars_for_java_debugger, true, true)

-- Completion for launch.json uses the VS Code debugger schemas in schemas/launch.json.
-- Property names there are copied from each debugger's configurationAttributes, not invented.
local launch_schema = vim.fn.stdpath("config") .. "/schemas/launch.json"
vim.lsp.config("jsonls", {
  init_options = {
    provideFormatter = false,
  },
  settings = {
    json = {
      validate = { enable = true },
      schemas = {
        {
          fileMatch = { "launch.json", "*-dap.json" },
          url = vim.uri_from_fname(launch_schema),
        },
      },
    },
  },
})

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
