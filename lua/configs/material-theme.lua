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
    local function lighten(hex, amount)
      hex = hex:gsub("#", "")
      local r = tonumber(hex:sub(1, 2), 16)
      local g = tonumber(hex:sub(3, 4), 16)
      local b = tonumber(hex:sub(5, 6), 16)
      r = math.min(255, math.floor(r + (255 - r) * amount))
      g = math.min(255, math.floor(g + (255 - g) * amount))
      b = math.min(255, math.floor(b + (255 - b) * amount))
      return string.format("#%02X%02X%02X", r, g, b)
    end
    -- Light: pale gray vs #FAFAFA. Deep ocean: dark blue gutter.
    local gutter_bg = vim.o.background == "light" and lighten(colors.editor.active, 0.55) or "#0D1A36"
    return {
      Visual = { bg = "#0042ff", fg = "#ffffff" },
      SpellBad = spell_bad,
      SpellCap = {},
      SpellLocal = {},
      SpellRare = {},
      SignColumn = { bg = gutter_bg, fg = colors.editor.fg },
      FoldColumn = { bg = gutter_bg, fg = colors.main.blue },
      LineNr = { bg = gutter_bg, fg = colors.editor.line_numbers },
    }
  end,
  lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )
}
