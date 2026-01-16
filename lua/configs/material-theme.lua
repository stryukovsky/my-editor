require("material").setup {
  styles = { -- Give comments style such as bold, italic, underline etc.
    comments = {
      italic = true,
    },
    strings = {
      italic = true,
    },
    keywords = {},
    functions = {
      bold = true,
    },
    variables = {},
    operators = {},
    types = {
      italic = true,
    },
  },

  plugins = { -- Uncomment the plugins that you use to highlight them
    -- Available plugins:
    "blink",
    -- "coc",
    -- "colorful-winsep",
    "dap",
    -- "dashboard",
    -- "eyeliner",
    "fidget",
    -- "flash",
    "gitsigns",
    -- "harpoon",
    -- "hop",
    "illuminate",
    -- "indent-blankline",
    -- "lspsaga",
    -- "mini",
    "neo-tree",
    "neogit",
    -- "neorg",
    "neotest",
    -- "noice",
    "nvim-cmp",
    -- "nvim-navic",
    "nvim-notify",
    -- "nvim-tree",
    "nvim-web-devicons",
    "rainbow-delimiters",
    -- "sneak",
    "telescope",
    "trouble",
    "which-key",
  },
  custom_highlights = {
    -- TabLine = function(colors, _)
    --   return {
    --     fg = colors.main.gray,
    --     italic = true,
    --   }
    -- end,
    -- TabLineSel = function(_, highlights)
    --   return vim.tbl_extend("force", highlights.main_highlights.editor()["TabLineSel"], { bold = true })
    -- end,
  },
  lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )
}

