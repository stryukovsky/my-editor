local M = {}

local zen_mode = require "zen-mode"

-- statuscol.nvim reads number/relativenumber/foldcolumn and fillchars to render
-- the fold + lnum + sign column. zen-mode's fix_hl overwrites fillchars on
-- BufWinEnter, so restore them after that runs.
local STATUSCOL = "%{%v:lua.require('statuscol').get_statuscol_string()%}"
local BACKDROP = 0.90

-- Set by open_jobs(); regular <A-z> zen must not change wrap.
local is_current_session_todotxt_file = false

local function apply_todotxt_file_wrap(win)
  if win and vim.api.nvim_win_is_valid(win) then
    vim.wo[win].wrap = true
  end
end

local function disable_todotxt_file_wrap()
  if not is_current_session_todotxt_file then
    return
  end
  is_current_session_todotxt_file = false
  local ok, view = pcall(require, "zen-mode.view")
  if ok and view.parent and vim.api.nvim_win_is_valid(view.parent) then
    vim.wo[view.parent].wrap = false
  end
  vim.wo.wrap = false
end

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
    width = 90,
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
    if is_current_session_todotxt_file then
      apply_todotxt_file_wrap(win)
    end
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
    disable_todotxt_file_wrap()
  end,
}

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_zen_bg,
})

-- Close zen if a tab change would leave its floats behind.
vim.api.nvim_create_autocmd("TabLeave", {
  callback = function()
    require("utils.ui_prevent_mess")()
  end,
})

-- Open zen for the jobs file: wrap on, wrap off again when this zen session closes.
function M.open_todotxt_file()
  is_current_session_todotxt_file = true
  local view_ok, view = pcall(require, "zen-mode.view")
  if view_ok and view.is_open() then
    apply_todotxt_file_wrap(view.win)
    return
  end
  zen_mode.open {
    window = {
      options = {
        wrap = true,
      },
    },
  }
end

-- Toggle zen like other UI shortcuts: drop Telescope first, then open/close zen.
-- Registers dialog_component_callback_close so the next Telescope/UI key closes zen.
function M.toggle_ui()
  local close_telescope = require "mappings.close_telescope"
  local ui_prevent_mess = require "utils.ui_prevent_mess"
  local had_telescope = close_telescope()
  local view_ok, view = pcall(require, "zen-mode.view")
  local zen_open = view_ok and view.is_open()

  if zen_open and not had_telescope then
    ui_prevent_mess()
    _G.dialog_component_callback_close = function() end
    return
  end

  if type(_G.dialog_component_callback_close) == "function" then
    _G.dialog_component_callback_close()
  end

  view_ok, view = pcall(require, "zen-mode.view")
  if not (view_ok and view.is_open()) then
    zen_mode.open()
  end
  _G.dialog_component_callback_close = function()
    ui_prevent_mess()
    _G.dialog_component_callback_close = function() end
  end
end

return M
