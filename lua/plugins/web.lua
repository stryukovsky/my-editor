return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = require "configs.markdown-preview",
    ft = { "markdown" },
  },
  {
    "mistweaverco/kulala.nvim",
    keys = {},
    ft = { "http", "rest" },
    opts = {},
  },
}

