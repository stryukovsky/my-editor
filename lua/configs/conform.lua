local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    css = { "prettier" },
    markdown = { "prettier_markdown" },
    html = { "prettier" },
    json = { "prettier" },
    jsonc = { "prettier" },
    scala = { "scalafmt" },
    typescript = { "prettier" },
    javascript = { "prettier" },
    go = { "gofumpt" },
    rust = { "rustfmt" },
    python = { "black" },
    xml = { "xmlformatter" },
    solidity = { "forge_fmt" },
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
    forge_fmt = {
      command = "forge",

      args = {"fmt",  "$FILENAME" },
      stdin = false,
    },
  },
}

return options
