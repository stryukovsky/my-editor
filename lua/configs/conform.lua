local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    markdown = { "mdformat" },
    html = { "prettier" },
    json = { "prettier" },
    scala = { "scalafmt" },
    typescript = { "prettier" },
    javascript = { "prettier" },
    go = { "gofumpt" },
    rust = { "rustfmt" },
    python = { "black" },
    xml = { "xmlformatter" },
    solidity = { "prettier_for_solidity" },
  },
  formatters = {
    mdformat = {
      args = { "--wrap", "80", "-" },
    },
    prettier_for_solidity = {
      command = "npx",

      args = { "prettier", "--write", "--plugin=prettier-plugin-solidity", "$FILENAME" },
      stdin = false,
    },
  },
}

return options
