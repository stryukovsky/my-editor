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
function M.ready(buf, navigation)
  buf = target(buf)
  local staged = MiniDiff.get_staged_state(buf)
  if navigation and staged and staged.status ~= "ready" then
    M.message(buf, "Staged diff is " .. staged.status .. (staged.reason and (": " .. staged.reason) or ""))
    return false
  end
  local state = MiniDiff.get_buf_state(buf)
    or { status = "unavailable", reason = "Diff is not enabled for this buffer" }
  if state.status == "ready" then
    if navigation and #(MiniDiff.get_navigation_hunk_ranges(buf) or {}) > 0 then
      return true
    end
    local summary = vim.b[buf].minidiff_summary
    if summary and (summary.n_ranges or 0) > 0 then
      return true
    end
    if staged and staged.status == "ready" and #(MiniDiff.get_navigation_hunk_ranges(buf) or {}) > 0 then
      M.message(buf, "Only staged changes; this action applies to unstaged hunks")
    else
      M.message(buf, "No changes in this buffer")
    end
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

function M.no_hunk(buf)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local staged = MiniDiff.get_staged_data(buf)
  for _, hunk in ipairs(staged and staged.buffer_hunks or {}) do
    if hunk.buf_start <= line and line <= hunk.buf_start + math.max(hunk.buf_count, 1) - 1 then
      return M.message(buf, "Only staged changes here; this action applies to unstaged hunks")
    end
  end
  M.message(buf, "No hunk under cursor")
end

function M.run(buf, action)
  local ok, err = pcall(action)
  if not ok then
    M.message(buf, tostring(err), vim.log.levels.ERROR)
  end
  return ok
end

return M
