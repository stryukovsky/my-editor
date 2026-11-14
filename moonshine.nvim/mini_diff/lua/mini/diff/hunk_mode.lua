local M = {}

function M.wanted()
  return vim.g.minidiff_overlay == true
end

function M.sync(buf)
  local diff = require "mini.diff"
  local data = diff.get_buf_data(buf)
  if data and data.overlay ~= M.wanted() then
    pcall(diff.toggle_overlay, buf)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniDiffUpdated",
    group = vim.api.nvim_create_augroup(
      "MiniDiffOverlayGlobal",
      { clear = true }
    ),
    callback = function(ev)
      M.sync(ev.buf == 0 and vim.api.nvim_get_current_buf() or ev.buf)
    end,
  })
end

function M.toggle()
  vim.g.minidiff_overlay = not M.wanted()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    M.sync(buf)
  end
  require("integrations.notify").replace(
    "minidiff.overlay",
    "MiniDiff",
    M.wanted() and "Hunk overlay on" or "Hunk overlay off",
    vim.log.levels.INFO
  )
end

-- Keep the public per-buffer operation independent of the global preference.
function M.toggle_buffer(buf, H)
  local cache = H.cache[buf]
  if not cache then
    H.error(string.format("Buffer %d is not enabled.", buf))
  end
  cache.overlay = not cache.overlay
  H.clear_all_diff(buf)
  H.schedule_diff_update(buf, 0)
end

return M
