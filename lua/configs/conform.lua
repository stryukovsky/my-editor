local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    json = {"prettier"},
    typescript = { "prettier" },
    javascript = { "prettier" },
    go = { "goimports" },
    rust = { "rustfmt" },
    solidity = { "solhint" },
  },

  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 500,
    lsp_fallback = true,
  },
}

return options
