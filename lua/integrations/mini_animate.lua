local M = {}
local generation = 0

-- Only explicit centering mappings animate; ordinary navigation stays native.
local function center(command, field)
  generation = generation + 1
  local id = generation
  local animate = require "mini.animate"
  local win, buf =
    vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local before = vim.fn.winsaveview()
  vim.cmd("normal! " .. command)
  local target = vim.fn.winsaveview()
  local config =
    vim.tbl_deep_extend("force", animate.config, vim.b.minianimate_config or {})
  local delta = target[field] - before[field]
  if delta == 0 or vim.g.minianimate_disable or vim.b.minianimate_disable then
    return
  end
  local steps = math.min(math.abs(delta), 60)
  vim.fn.winrestview(
    vim.tbl_extend("force", target, { [field] = before[field] })
  )
  local previous = vim.fn.winsaveview()
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
      view.leftcol ~= previous.leftcol
      or view.topline ~= previous.topline
      or view.lnum ~= target.lnum
      or view.col ~= target.col
      or view.topfill ~= previous.topfill
      or view.skipcol ~= previous.skipcol
    then
      return false
    end
    local position = before[field] + math.floor(delta * step / steps + 0.5)
    vim.fn.winrestview(vim.tbl_extend("force", target, { [field] = position }))
    previous = vim.fn.winsaveview()
    return step < steps
  end, function(step)
    return config.scroll.timing(step, steps)
  end)
end

function M.center_vertical(count)
  center((count and count > 0 and tostring(count) or "") .. "zz", "topline")
end

function M.center_horizontal()
  center("zszH", "leftcol")
end

return M
