local trouble = require "trouble"
local is_ollama_installed = require "utils.is_ollama_installed"
local dap_output = require "configs.debug_output"
local git_fetch = require "configs.periodic-git-fetch"
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
local function get_neotree_path()
  -- Safely check if neo-tree manager is loaded
  local status, manager = pcall(require, "neo-tree.sources.manager")
  if not status then
    return ""
  end

  -- Get current state of the filesystem source
  local state = manager.get_state "filesystem"
  if not state or not state.tree then
    return ""
  end

  -- Get the node under the cursor
  local node = state.tree:get_node()
  if not node then
    return ""
  end

  -- Format the node absolute path relative to the current CWD
  return vim.fn.fnamemodify(node:get_id(), ":.")
end

local function to_hex_color(color)
  return "#" .. string.format("%x", color)
end

local function hl_fg(name, default)
  local hl = vim.api.nvim_get_hl(0, { name = name })
  return hl and hl.fg and to_hex_color(hl.fg) or default
end

local defaults_for_x_component = {
  {
    "diagnostics",
    diagnostics_color = {
      error = { fg = hl_fg("Red", "#ec5f67") },
      warn = { fg = hl_fg("Orange", "#ff9e64") },
      info = { fg = hl_fg("Blue", "#00bfff") },
      hint = { fg = hl_fg("Green", "#10b981") },
    },
  },

  "lsp_status",
  "filetype",
}

local function lualine_x_component()
  if not is_ollama_installed() then
    return defaults_for_x_component
  end
  local success, config = pcall(function()
    return vim.list_extend({
      require "minuet.lualine",
    }, defaults_for_x_component)
  end)
  if success then
    return config
  else
    return defaults_for_x_component
  end
end

local function get_lualine_theme()
  local bg_color = to_hex_color(vim.api.nvim_get_hl(0, { name = "Normal" }).bg)
  local fg_color = to_hex_color(vim.api.nvim_get_hl(0, { name = "Normal" }).fg)
  local lualine_theme = require "lualine.themes.material-nvim"
  for k, _ in pairs(lualine_theme) do
    lualine_theme[k].b.bg = bg_color
    lualine_theme[k].b.fg = fg_color
    if lualine_theme[k]["c"] ~= nil then
      lualine_theme[k].c.bg = bg_color
      lualine_theme[k].c.fg = fg_color
    end
  end
  lualine_theme.replace.a = { fg = "#ffffff", bg = "#ff0000" }
  lualine_theme.replace.z = { fg = "#ffffff", bg = "#ff0000" }
  lualine_theme.visual.a = { fg = "#ffffff", bg = "#0000ff" }
  lualine_theme.visual.z = { fg = "#ffffff", bg = "#0000ff" }

  return lualine_theme
end

local function gitsigns_diff()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed,
    }
  end
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
    globalstatus = true,
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      git_fetch.lualine_component(),
      "branch",
      {
        "diff",
        source = gitsigns_diff,
        symbols = { added = " ", modified = " ", removed = " " },
        diff_color = {
          added = { fg = hl_fg("Green", "#98be65") },
          modified = { fg = hl_fg("Orange", "#ff9e64") },
          removed = { fg = hl_fg("Red", "#ec5f67") },
        },
      },
    },
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

    lualine_x = lualine_x_component(),
    -- lualine_y = {
    --   {
    --     function()
    --       return "󰛢"
    --     end,
    --     cond = function()
    --       return packafge.loaded["grapple"] and require("grapple").exists()
    --     end,
    --   },
    -- },
    lualine_y = { dap_output.lualine_component() },
    lualine_z = { "location", "selectioncount" },
  },
  tabline = {},
  winbar = {},
  inactive_winbar = {},
  extensions = {
    {
      sections = {
        lualine_a = {
          function()
            return "NEO-TREE"
          end,
        },
        lualine_c = { get_neotree_path }, -- Displays relative path from CWD
      },
      filetypes = { "neo-tree" },
    },
  },
  "trouble",
  "oil",
  "toggleterm",
  "lazy",
  "mason",
}
