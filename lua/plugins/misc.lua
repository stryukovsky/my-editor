return {
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", lazy = false },
  {
    "Julian/lean.nvim",
    event = { "BufReadPre *.lean", "BufNewFile *.lean" },
  },
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
  {
    "rcarriga/nvim-notify",
    lazy = false,
    config = function()
      require("integrations.notify").setup()
    end,
  },
  { "stryukovsky/lspeek.nvim", branch = "feature/add-fragile-mode" },
}
