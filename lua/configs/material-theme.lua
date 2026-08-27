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
  custom_colors = function(colors)
    if vim.g.material_style ~= "lighter" then
      return
    end

    -- Matte wheat paper: warm near-whites without reducing text contrast.
    colors.main.white = "#fff7e8"
    colors.editor.bg = "#f7f1e3"
    colors.editor.bg_alt = "#fcf6e9"
    colors.editor.white = "#fff7e8"
    colors.editor.contrast = "#eee4ce"
    colors.editor.active = "#e7dcc4"
    colors.editor.highlight = "#e7dcc4"
    colors.editor.border = "#d8c8aa"
    colors.editor.selection = "#e5d5a6"
    colors.editor.line_numbers = "#c5b79e"
    colors.editor.disabled = "#c9bdb0"
    colors.editor.accent = "#c49a2e"
    colors.editor.fg = "#5d5140"
    colors.editor.fg_dark = "#8b7d6d"
    colors.syntax.comments = "#9b8a72"
    colors.backgrounds.sidebars = colors.editor.bg
    colors.backgrounds.floating_windows = colors.editor.bg
    colors.backgrounds.non_current_windows = colors.editor.bg
    colors.backgrounds.bg_blend = colors.editor.bg
    colors.backgrounds.cursor_line = colors.editor.active
  end,
  custom_highlights = function(colors)
    local spell_bad = { undercurl = true }
    if vim.g.grammar_strict then
      spell_bad = { fg = colors.main.red, italic = true, undercurl = true }
    end
    return {
      Visual = { bg = "#0042ff", fg = "#fff7e8" },
      SpellBad = spell_bad,
      SpellCap = {},
      SpellLocal = {},
      SpellRare = {},
    }
  end,
  lualine_style = "stealth", -- Lualine style ( can be 'stealth' or 'default' )
}
