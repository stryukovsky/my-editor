return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
  },
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required

      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
    },
  },
  { "nvim-telescope/telescope-ui-select.nvim" },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
  {
    "saadparwaiz1/cmp_luasnip",
  },
  {
    "Wansmer/treesj",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    dependencies = { "rafamadriz/friendly-snippets" },

    -- use a release tag to download pre-built binaries
    version = "1.*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    opts_extend = { "sources.default" },
  },
  {
    "saghen/blink.compat",
    -- use v2.* for blink.cmp v1.*
    version = "2.*",
    -- lazy.nvim will automatically load the plugin when it's required by blink.cmp
    lazy = true,
    -- make sure to set opts so that lazy.nvim calls blink.compat's setup
    opts = {},
  },
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },
  { "nvim-pack/nvim-spectre" },
  {
    "nvim-lualine/lualine.nvim",
  },
  {
    "marko-cerovac/material.nvim",
  },
  {
    "ThePrimeagen/refactoring.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    lazy = false,
  },
  {
    "folke/which-key.nvim",
  },
  {
    "romgrk/barbar.nvim",
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
      -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
    },
    lazy = false, -- neo-tree will lazily load itself
  },

  {
    "lewis6991/gitsigns.nvim",
  },

  {
    "nvim-telescope/telescope.nvim",
    -- tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "debugloop/telescope-undo.nvim",
    },
  },
  { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },
  {
    "stevearc/oil.nvim",
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
  },
  {
    "folke/lazydev.nvim",
    ft = "lua", -- only load on lua files
    opts = {
      library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      },
    },
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  }, -- lazy.nvim
  {
    "numToStr/Comment.nvim",
  },
  { "gbprod/yanky.nvim" },
  {
    "jake-stewart/multicursor.nvim",
    branch = "1.0",
  },
  {
    "johmsalas/text-case.nvim",
    config = function()
      require("textcase").setup {}
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "codecompanion" },
    lazy = true,
  },
  { "stryukovsky/git-conflict.nvim", branch = "main" },
  { "stryukovsky/rainbow-delimiters.nvim" },
}
