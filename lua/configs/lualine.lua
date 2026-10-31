local trouble = require "trouble"
local dap_output = require "debug_output"
local git_fetch = require "configs.periodic-git-fetch"
local git_branch = require "configs.lualine_branch"
local is_it_merge = require "configs.is_it_merge"
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

  -- Progress spinner rewrites the whole bar when a completion request starts.
  {
    "lsp_status",
    symbols = {
      spinner = { "" },
      done = "",
    },
  },
  "filetype",
}

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
  lualine_theme.normal.a = { fg = "#fff7e8", bg = "#c49a2e", gui = "bold" }
  lualine_theme.replace.a = { fg = "#ffffff", bg = "#ff0000" }
  lualine_theme.replace.z = { fg = "#ffffff", bg = "#ff0000" }
  lualine_theme.visual.a = { fg = "#ffffff", bg = "#0000ff" }
  lualine_theme.visual.z = { fg = "#ffffff", bg = "#0000ff" }

  return lualine_theme
end

-- Empty local statuslines (including new documentation floats) use this fallback.
-- Keep it rendered so a redraw before lualine's next refresh cannot flash blank.
local refresh_group = vim.api.nvim_create_augroup("LualineFiletypeRefresh", { clear = true })
vim.api.nvim_create_autocmd("OptionSet", {
  group = refresh_group,
  pattern = "statusline",
  callback = function()
    if vim.v.option_type == "local" and vim.api.nvim_win_get_config(0).relative == "" then
      vim.go.statusline = vim.v.option_new
    end
  end,
})

local function setup_lualine(opts)
  local lualine = require "lualine"
  lualine.setup(opts)
  -- setup() leaves a blank statusline until the refresh timer. Paint it now.
  lualine.refresh { force = true }
  -- OptionSet does not run during startup.
  if vim.api.nvim_win_get_config(0).relative == "" then
    vim.go.statusline = vim.wo.statusline
  end
end

vim.api.nvim_create_autocmd({ "ColorScheme" }, {
  pattern = "*",
  callback = function()
    setup_lualine {
      options = {
        theme = get_lualine_theme(),
      },
    }
  end,
})

setup_lualine {
  options = {
    theme = get_lualine_theme(),
    globalstatus = true,
    -- Completion/documentation floats must not replace the editor's global bar.
    ignore_focus = function(win)
      return vim.api.nvim_win_get_config(win).relative ~= ""
    end,
    refresh = {
      events = {
        "WinEnter",
        "BufEnter",
        "BufWritePost",
        "SessionLoadPost",
        "FileChangedShellPost",
        "VimResized",
        "CursorMoved",
        "CursorMovedI",
        "ModeChanged",
        "TabEnter",
      },
    },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {
      git_fetch.lualine_component(),
      git_branch.lualine_component(),
      is_it_merge.lualine_component(),
      require("configs.minidiff").lualine_hunks,
    },
    lualine_c = {
      {
        "filename",
        file_status = true, -- Displays file status (readonly status, modified status)
        newfile_status = false, -- Display new file status (new file means no write after created)
        path = 1, -- 0: Just the filename
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

    lualine_x = defaults_for_x_component,
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
        lualine_b = {
          git_fetch.lualine_component(),
          git_branch.lualine_component(),
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

-- FileType is not a lualine refresh event; only refresh for editor buffers.
vim.api.nvim_create_autocmd("FileType", {
  group = refresh_group,
  callback = function()
    if vim.api.nvim_win_get_config(0).relative == "" then
      require("lualine").refresh()
    end
  end,
})
