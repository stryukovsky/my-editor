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
    xml = { "xmlformatter" },
    solidity = { "prettier_for_solidity" },
  },
  formatters = {
    prettier_for_solidity = {
      command = "npx",

      args = { "prettier", "--write", "--plugin=prettier-plugin-solidity", "$FILENAME" },
      stdin = false,
    },
  },
}

return options
