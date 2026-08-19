local zen_mode = require "zen-mode"

-- statuscol.nvim reads number/relativenumber/foldcolumn and fillchars to render
-- the fold + lnum + sign column. zen-mode's fix_hl overwrites fillchars on
-- BufWinEnter, so restore them after that runs.
local STATUSCOL = "%{%v:lua.require('statuscol').get_statuscol_string()%}"
local BACKDROP = 0.90

-- zen-mode uses `highlight default ZenBg`, which is computed at setup() — before
-- theme.lua — and then never updates. Force ZenBg from the current Normal bg.
local function apply_zen_bg()
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  if not normal.bg then
    vim.api.nvim_set_hl(0, "ZenBg", { link = "Normal" })
    return
  end
  local hex = string.format("#%06x", normal.bg)
  local bg = require("zen-mode.util").darken(hex, BACKDROP)
  vim.api.nvim_set_hl(0, "ZenBg", { fg = bg, bg = bg })
end

local function apply_statuscol(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  local wo = vim.wo[win]
  wo.number = true
  wo.relativenumber = true
  wo.foldcolumn = "1"
  wo.statuscolumn = STATUSCOL
  wo.fillchars = vim.go.fillchars
end

zen_mode.setup {
  window = {
    backdrop = BACKDROP,
    width = 120,
    height = 1,
    options = {
      number = true,
      relativenumber = true,
      foldcolumn = "1",
      cursorcolumn = false,
      list = false,
    },
  },
  on_open = function(win)
    apply_zen_bg()
    apply_statuscol(win)
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = vim.api.nvim_create_augroup("ZenStatusCol", { clear = true }),
      callback = function()
        vim.schedule(function()
          apply_statuscol(win)
        end)
      end,
    })
  end,
  on_close = function()
    pcall(vim.api.nvim_del_augroup_by_name, "ZenStatusCol")
  end,
}

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_zen_bg,
})

-- zen-mode floats belong to the current tab and error if the tab changes under them.
vim.api.nvim_create_autocmd("TabLeave", {
  callback = function()
    require("utils.close_zen")()
  end,
})
