require("material").setup {
  styles = { -- Give comments style such as bold, italic, underline etc.
    comments = {
      italic = true,
    },
    strings = {
      italic = true,
    },
    keywords = {
      italic = true,
    },
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
    "dashboard",
    -- "eyeliner",
    "fidget",
    "flash",
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
  custom_highlights = function(colors)
    local spell_bad = { undercurl = true }
    if vim.g.grammar_strict then
      spell_bad = { fg = colors.main.red, italic = true, undercurl = true }
    end
    return {
      Visual = { bg = "#0042ff", fg = "#ffffff" },
      SpellBad = spell_bad,
      SpellCap = {},
      SpellLocal = {},
      SpellRare = {},
    }
  end,
  lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )
}
