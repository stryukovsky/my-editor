local MiniDiff = require "mini.diff"
local notify = require "integrations.notify"
local M = {}

local function target(buf)
  return (not buf or buf == 0) and vim.api.nvim_get_current_buf() or buf
end

function M.message(buf, message, level)
  buf = target(buf)
  local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
  notify.replace(
    "minidiff.buffer." .. buf,
    "MiniDiff · " .. (name ~= "" and name or "[No Name]"),
    message,
    level or vim.log.levels.INFO
  )
end

--- Return true only for current, nonempty diff results. Never queue an action.
function M.ready(buf)
  buf = target(buf)
  local state = MiniDiff.get_buf_state(buf)
    or { status = "unavailable", reason = "Diff is not enabled for this buffer" }
  if state.status == "ready" then
    local summary = vim.b[buf].minidiff_summary
    if summary and (summary.n_ranges or 0) > 0 then
      return true
    end
    M.message(buf, "No changes in this buffer")
  elseif state.status == "loading" then
    M.message(buf, "Diff is loading for this buffer")
  elseif state.status == "updating" then
    M.message(buf, "Diff is updating for this buffer")
  else
    local failed = state.status == "failed"
    local message = failed and "Diff computation failed"
      or "Diff is unavailable"
    if state.reason then
      message = message .. ": " .. state.reason
    end
    M.message(
      buf,
      message,
      failed and vim.log.levels.ERROR or vim.log.levels.INFO
    )
  end
  return false
end

function M.run(buf, action)
  local ok, err = pcall(action)
  if not ok then
    M.message(buf, tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

return M
