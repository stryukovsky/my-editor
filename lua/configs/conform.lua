local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    html = { "prettier" },
    json = { "prettier" },
    typescript = { "prettier" },
    javascript = { "prettier" },
    go = { "gofumpt" },
    rust = { "rustfmt" },
    python = { "black" },
  },
}

return options
