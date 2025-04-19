-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@class ChadrcConfig
local M = {}
M.base46 = {
  theme = "carbonfox",

  hl_override = {
    Comment = { italic = true },
    ["@comment"] = { italic = true },
  },
}
M.nvdash = {
  -- nvdash display condition is synced with auto-session, so here we need to skip its load on startup
  load_on_startup = false, -- nvdash is started on startup in autocmd
  header = {
    "                            ",
    "     ▄▄         ▄ ▄▄▄▄▄▄▄   ",
    "   ▄▀███▄     ▄██ █████▀    ",
    "   ██▄▀███▄   ███           ",
    "   ███  ▀███▄ ███           ",
    "   ███    ▀██ ███           ",
    "   ███      ▀ ███           ",
    "   ▀██ █████▄▀█▀▄██████▄    ",
    "     ▀ ▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀   ",
    "                            ",
    "                            ",
  },
  buttons = {
    { txt = "󱥚  Themes", keys = "th", cmd = ":lua require('nvchad.themes').open()" },
    { txt = "  Mappings", keys = "ch", cmd = "NvCheatsheet" },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },

    {
      txt = function()
        local stats = require("lazy").stats()
        local ms = math.floor(stats.startuptime) .. " ms"
        return "  Loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms
      end,
      hl = "NvDashFooter",
      no_gap = true,
    },

    { txt = "─", hl = "NvDashFooter", no_gap = true, rep = true },
  },
}

local function shorten(v)
  local value = tostring(v)
  if #value > 20 then
    return value.sub(value, 1, 7) .. "..." .. value.sub(value, #value - 7, #value)
  else
    return value
  end
end

M.ui = {
  tabufline = {
    lazyload = false,
  },
  statusline = {
    theme = "default",
    separator_style = "default",
    order = { "mode", "file", "f", "%=", "lsp_msg", "%=", "diagnostics", "git_improved", "lsp", "cwd", "cursor" },
    modules = {
      git_improved = function()
        local branch = shorten(vim.fn.system "git branch --show-current 2> /dev/null | tr -d '\n'")
        if branch ~= "" then
          return "  " .. branch .. " "
        else
          return ""
        end
      end,

      f = "%f",
    },
  },
  cmp = {
    style = "atom",
  },
}
return M
