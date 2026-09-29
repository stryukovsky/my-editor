-- mason and stuff which is related to mason (DAP, lspconfig, etc)
return {
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "j-hui/fidget.nvim",
  },
  {
    "neovim/nvim-lspconfig",
  },
  {
    "mfussenegger/nvim-dap",
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",

      { "fredrikaverpil/neotest-golang", version = "*" }, -- Installation
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
      "stevanmilic/neotest-scala",
    },
  },
  { "mfussenegger/nvim-jdtls" },
  {
    "leoluz/nvim-dap-go",
    ft = "go",
    dependencies = "mfussenegger/nvim-dap",
    config = function(_, opts)
      require("dap-go").setup(opts)
    end,
  },
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "mfussenegger/nvim-dap",
    },
    lazy = true,
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- Recommended
    lazy = false, -- This plugin is already lazy
  },
  {
    "mfussenegger/nvim-dap-python",
    dependencies = "mfussenegger/nvim-dap",
    lazy = true,
    -- no ft/opts: lazy must not call setup() on FileType python
    config = function() end,
  },
}
