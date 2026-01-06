local trouble = require "trouble"
local symbols = trouble.statusline {
  mode = "lsp_document_symbols",
  groups = {},
  title = false,
  filter = { range = true },
  format = "{kind_icon}{symbol.name:Normal}",
  -- The following line is needed to fix the background color
  -- Set it to the lualine section you want to use
  hl_group = "lualine_c_normal",
}

local function to_hex_color(color)
  return "#" .. string.format("%x", color)
end

local function get_lualine_theme()
  local bg_color = to_hex_color(vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
  -- local fg_color = to_hex_color(vim.api.nvim_get_hl(0, { name = "Normal" }).fg)
  local lualine_theme = require "lualine.themes.auto"
  -- lualine_theme.normal.c.bg = bg_color
  -- lualine_theme.normal.b.bg = bg_color
  for k, _ in pairs(lualine_theme) do
    lualine_theme[k].b.bg = bg_color
    lualine_theme[k].c.bg = bg_color
  end
  return lualine_theme
end

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  pattern = "*",
  callback = function()
    require("lualine").setup {
      options = {
        theme = get_lualine_theme(),
      },
    }
  end,
})

require("lualine").setup {
  options = {
    theme = get_lualine_theme(),
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = {
      {
        "filename",
        file_status = true, -- Displays file status (readonly status, modified status)
        newfile_status = false, -- Display new file status (new file means no write after created)
        path = 3, -- 0: Just the filename
        -- 1: Relative path
        -- 2: Absolute path
        -- 3: Absolute path, with tilde as the home directory
        -- 4: Filename and parent dir, with tilde as the home directory

        shorting_target = 40, -- Shortens path to leave 40 spaces in the window
        -- for other components. (terrible name, any suggestions?)
        symbols = {
          modified = "[+]", -- Text to show when the file is modified.
          readonly = "[-]", -- Text to show when the file is non-modifiable or readonly.
          unnamed = "[No Name]", -- Text to show for unnamed buffers.
          newfile = "[New]", -- Text to show for newly created file before first write
        },
      },
      {
        symbols.get,
        cond = symbols.has,
      },
    },

    lualine_x = {
      {
        require "minuet.lualine",
      },
      "lsp_status",
      "filetype",
    },
    lualine_y = {
      {
        function()
          return "󰛢"
        end,
        cond = function()
          return package.loaded["grapple"] and require("grapple").exists()
        end,
      },
    },
    lualine_z = { "location", "selectioncount" },
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {},
}
