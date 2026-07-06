return {
  {
    "booperlv/nvim-gomove",
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = require "configs.markdown-preview",
    ft = { "markdown" },
  },
  {
    "RRethy/vim-illuminate",
  },
  {
    "cbochs/grapple.nvim",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", lazy = true },
    },
  },
  {
    "Wansmer/langmapper.nvim",
    lazy = false,
    priority = 1, -- High priority is needed if you will use `autoremap()`
  },
  {
    "Wansmer/sibling-swap.nvim",
  },
  {
    "fei6409/log-highlight.nvim",
    opts = {},
  },
}
