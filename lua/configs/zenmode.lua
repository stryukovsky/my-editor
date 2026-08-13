local zen_mode = require "zen-mode"

-- statuscol.nvim reads number/relativenumber/foldcolumn and fillchars to render
-- the fold + lnum + sign column. zen-mode's fix_hl overwrites fillchars on
-- BufWinEnter, so restore them after that runs.
local STATUSCOL = "%{%v:lua.require('statuscol').get_statuscol_string()%}"

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
    backdrop = 0.95,
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
