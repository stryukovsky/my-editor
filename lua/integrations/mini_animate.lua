local M = {}
local generation = 0

-- MiniAnimate handles vertical scrolling; zx also needs horizontal view steps.
function M.center_horizontal()
  generation = generation + 1
  local id = generation
  local animate = require "mini.animate"
  local win, buf =
    vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local before = vim.fn.winsaveview()
  vim.cmd "normal! zszH"
  local target = vim.fn.winsaveview()
  local config =
    vim.tbl_deep_extend("force", animate.config, vim.b.minianimate_config or {})
  local delta = target.leftcol - before.leftcol
  if
    delta == 0
    or vim.g.minianimate_disable
    or vim.b.minianimate_disable
    or not config.scroll.enable
  then
    return
  end
  local steps = math.min(math.abs(delta), 60)
  local leftcol = before.leftcol
  vim.fn.winrestview { leftcol = leftcol }
  animate.animate(function(step)
    if
      id ~= generation
      or vim.api.nvim_get_current_win() ~= win
      or vim.api.nvim_get_current_buf() ~= buf
    then
      return false
    end
    local view = vim.fn.winsaveview()
    -- New navigation takes precedence over the unfinished animation.
    if
      view.leftcol ~= leftcol
      or view.lnum ~= target.lnum
      or view.col ~= target.col
      or view.topline ~= target.topline
    then
      return false
    end
    leftcol = before.leftcol + math.floor(delta * step / steps + 0.5)
    vim.fn.winrestview { leftcol = leftcol }
    return step < steps
  end, function(step)
    return config.scroll.timing(step, steps)
  end)
end

return M
