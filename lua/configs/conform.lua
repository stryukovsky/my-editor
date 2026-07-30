local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    markdown = { "prettier_markdown" },
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
    -- proseWrap only applies to markdown; keep it off the shared prettier formatter.
    prettier_markdown = {
      command = "prettier",
      args = {
        "--stdin-filepath",
        "$FILENAME",
        "--parser",
        "markdown",
        "--print-width",
        "80",
        "--prose-wrap",
        "always",
      },
    },
    prettier_for_solidity = {
      command = "npx",

      args = { "prettier", "--write", "--plugin=prettier-plugin-solidity", "$FILENAME" },
      stdin = false,
    },
  },
}

return options
