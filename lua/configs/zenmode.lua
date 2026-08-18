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

-- render-markdown anti-conceal shows the cursor line as raw markdown.
-- Remember the previous value (global + per-buffer) and turn it off in zen.
local anti_conceal_prev ---@type { global: boolean, bufs: table<integer, boolean> }|nil

local function refresh_render_markdown()
  local ok_state, state = pcall(require, "render-markdown.state")
  local ok_ui, ui = pcall(require, "render-markdown.core.ui")
  if not (ok_state and ok_ui) then
    return
  end
  for buf, config in pairs(state.cache) do
    if config.enabled and vim.api.nvim_buf_is_valid(buf) then
      for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        ui.update(buf, win, "ZenMode", true)
      end
    end
  end
end

local function set_anti_conceal_enabled(enabled)
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end
  state.config.anti_conceal.enabled = enabled
  for _, config in pairs(state.cache) do
    config.anti_conceal.enabled = enabled
  end
end

local function disable_anti_conceal()
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end
  local bufs = {}
  for buf, config in pairs(state.cache) do
    bufs[buf] = config.anti_conceal.enabled
  end
  anti_conceal_prev = {
    global = state.config.anti_conceal.enabled,
    bufs = bufs,
  }
  set_anti_conceal_enabled(false)
  refresh_render_markdown()
end

local function restore_anti_conceal()
  local prev = anti_conceal_prev
  anti_conceal_prev = nil
  if not prev then
    return
  end
  local ok, state = pcall(require, "render-markdown.state")
  if not ok or not state.config then
    return
  end
  state.config.anti_conceal.enabled = prev.global
  for buf, config in pairs(state.cache) do
    local enabled = prev.bufs[buf]
    if enabled == nil then
      enabled = prev.global
    end
    config.anti_conceal.enabled = enabled
  end
  refresh_render_markdown()
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
    disable_anti_conceal()
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
    restore_anti_conceal()
  end,
}

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_zen_bg,
})
