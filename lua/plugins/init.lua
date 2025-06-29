local function local_llm_streaming_handler(chunk, ctx, F)
  if not chunk then
    return ctx.assistant_output
  end
  local tail = chunk:sub(-1, -1)
  if tail:sub(1, 1) ~= "}" then
    ctx.line = ctx.line .. chunk
  else
    ctx.line = ctx.line .. chunk
    local status, data = pcall(vim.fn.json_decode, ctx.line)
    if not status or not data.message.content then
      return ctx.assistant_output
    end
    ctx.assistant_output = ctx.assistant_output .. data.message.content
    F.WriteContent(ctx.bufnr, ctx.winid, data.message.content)
    ctx.line = ""
  end
  return ctx.assistant_output
end

local function local_llm_parse_handler(chunk)
  local assistant_output = chunk.message.content
  return assistant_output
end

return {
  {
    "Kurama622/llm.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    cmd = { "LLMSessionToggle", "LLMSelectedTextHandler" },
    config = function()
      local tools = require "llm.tools"
      require("llm").setup {
        url = "http://localhost:11434/api/chat",
        api_type = "ollama",
        temperature = 0.3,
        top_p = 0.7,
        model = "deepseek-r1",
        streaming_handler = local_llm_streaming_handler,
        app_handler = {
          Completion = {
            style = "virtual_text",
            handler = tools.completion_handler,
            opts = {
              -------------------------------------------------
              ---                   ollama
              -------------------------------------------------
              url = "http://localhost:11434/v1/completions",
              model = "qwen2.5-coder:1.5b",
              api_type = "ollama",

              n_completions = 3,
              context_window = 512,
              max_tokens = 256,

              -- A mapping of filetype to true or false, to enable completion.
              filetypes = { sh = false },

              -- Whether to enable completion of not for filetypes not specifically listed above.
              default_filetype_enabled = true,

              auto_trigger = true,

              -- just trigger by { "@", ".", "(", "[", ":", " " } for `style = "nvim-cmp"`
              only_trigger_by_keywords = false,

              style = "virtual_text", -- nvim-cmp or blink.cmp

              timeout = 10, -- max request time

              -- only send the request every x milliseconds, use 0 to disable throttle.
              throttle = 1000,
              -- debounce the request in x milliseconds, set to 0 to disable debounce
              debounce = 400,

              --------------------------------
              ---   just for virtual_text
              --------------------------------
              keymap = {
                virtual_text = {
                  accept = {
                    mode = "i",
                    keys = "<C-a>",
                  },
                  next = {
                    mode = "i",
                    keys = "<C-j>",
                  },
                  prev = {
                    mode = "i",
                    keys = "<C-k>",
                  },
                  toggle = {
                    mode = "n",
                    keys = "<leader>cp",
                  },
                },
              },
            },
          },
          -- WordTranslate = {
          --   -- handler = tools.flexi_handler,
          --   prompt = "Translate the following text to Russian, please only return the translation",
          --   opts = {
          --     parse_handler = local_llm_parse_handler,
          --     exit_on_move = true,
          --     enter_flexible_window = false,
          --   },
          -- },
        },
           -- stylua: ignore
        keys = {
          -- The keyboard mapping for the input window.
          ["Input:Submit"]      = { mode = "n", key = "<cr>" },
          ["Input:Cancel"]      = { mode = {"n", "i"}, key = "<C-c>" },
          ["Input:Resend"]      = { mode = {"n", "i"}, key = "<C-r>" },

          -- only works when "save_session = true"
          ["Input:HistoryNext"] = { mode = {"n", "i"}, key = "<C-j>" },
          ["Input:HistoryPrev"] = { mode = {"n", "i"}, key = "<C-k>" },

          -- The keyboard mapping for the output window in "split" style.
          ["Output:Ask"]        = { mode = "n", key = "i" },
          ["Output:Cancel"]     = { mode = "n", key = "<C-c>" },
          ["Output:Resend"]     = { mode = "n", key = "<C-r>" },

          -- The keyboard mapping for the output and input windows in "float" style.
          ["Session:Toggle"]    = { mode = "n", key = "<leader>ac" },
          ["Session:Close"]     = { mode = "n", key = {"<esc>", "Q"} },

          -- Scroll
          ["PageUp"]            = { mode = {"i","n"}, key = "<C-b>" },
          ["PageDown"]          = { mode = {"i","n"}, key = "<C-f>" },
          ["HalfPageUp"]        = { mode = {"i","n"}, key = "<C-u>" },
          ["HalfPageDown"]      = { mode = {"i","n"}, key = "<C-d>" },
          ["JumpToTop"]         = { mode = "n", key = "gg" },
          ["JumpToBottom"]      = { mode = "n", key = "G" },
        },
      }
    end,
    keys = {
      { "<leader>ac", mode = "n", "<cmd>LLMSessionToggle<cr>" },
    },
  },
  -- CORE PLUGINS
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim", -- required
      "sindrets/diffview.nvim", -- optional - Diff integration

      -- Only one of these is needed.
      "nvim-telescope/telescope.nvim", -- optional
    },
  },
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    config = function()
      require("dashboard").setup {
        -- config
      }
    end,
    dependencies = { { "nvim-tree/nvim-web-devicons" } },
  },
  {
    "saadparwaiz1/cmp_luasnip",
  },
  {
    "onsails/lspkind.nvim",
  },
  {
    "nvim-tree/nvim-web-devicons",
  },
  {
    "L3MON4D3/LuaSnip",
    -- follow latest release.
    version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
    -- install jsregexp (optional!).
    dependencies = { "rafamadriz/friendly-snippets" },
    build = "make install_jsregexp",
  },
  -- {
  --   "hrsh7th/nvim-cmp",
  --   event = "InsertEnter",
  --   dependencies = {
  --     "hrsh7th/cmp-nvim-lsp",
  --     "hrsh7th/cmp-buffer",
  --     "hrsh7th/cmp-path",
  --     "hrsh7th/cmp-nvim-lsp-signature-help",
  --     "L3MON4D3/LuaSnip",
  --     "saadparwaiz1/cmp_luasnip",
  --   },
  -- },
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
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },
  {
    "mason-org/mason.nvim",
    opts = {},
  },
  {
    "nvim-lualine/lualine.nvim",
  },
  {
    "marko-cerovac/material.nvim",
  },
  {
    "j-hui/fidget.nvim",
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
    event = "VeryLazy",
    opts = require "configs.whichkey",
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show { global = true }
        end,
        desc = "Buffer Local Keymaps (which-key)",
      },
    },
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
    "neovim/nvim-lspconfig",
  },
  {
    "mfussenegger/nvim-dap",
  },
  {
    "lewis6991/gitsigns.nvim",
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
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
    opts = {
      ensure_installed = require "configs.treesitter",
    },
  },
  {
    "stevearc/oil.nvim",
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  {
    "sindrets/diffview.nvim",
  },
  {
    "olimorris/codecompanion.nvim",
  },
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-treesitter/nvim-treesitter",

      "nvim-neotest/neotest-go",
      "nvim-neotest/neotest-python",
      "nvim-neotest/neotest-jest",
      "stevanmilic/neotest-scala",
    },
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
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
      "MunifTanjim/nui.nvim",
      -- OPTIONAL:
      --   `nvim-notify` is only needed, if you want to use the notification view.
      --   If not available, we use `mini` as the fallback
      "rcarriga/nvim-notify",
    },
  },
  {
    "numToStr/Comment.nvim",
  },
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false, -- Never set this value to "*"! Never!
    opts = require "configs.avante",
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    },
  },
  -- LANGUAGE-SPECIFIC-PLUGINS
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
    },
    ft = { "scala", "sbt" },
    config = require "configs.scalametals",
  },
  {
    "mrcjkb/rustaceanvim",
    version = "^5", -- Recommended
    lazy = false, -- This plugin is already lazy
  },
  {
    "mfussenegger/nvim-dap-python",
  },
  -- SMALL functionalities
  {
    "karb94/neoscroll.nvim",
    opts = {},
  },
  {
    "booperlv/nvim-gomove",
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      file_types = { "markdown", "Avante" },
    },
    ft = { "markdown", "Avante" },
    lazy = true,
  },
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
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && yarn install",
    init = require "configs.markdown-preview",
    ft = { "markdown" },
  },
  {
    "rachartier/tiny-code-action.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim" },
      { "nvim-telescope/telescope.nvim" },
    },
    event = "LspAttach",
  },
  {
    "mistweaverco/kulala.nvim",
    keys = {},
    ft = { "http", "rest" },
    opts = {},
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
}
