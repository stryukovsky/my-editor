-- Pure staged snapshot helpers. Index hunks remain separate from display anchors.
local M = {}

-- Map index lines through index -> buffer edits. Removed spans use their
-- replacement (or the preceding surviving line) as a reachable display anchor.
function M.project(hunks, edits, line_count)
  local function project_line(line)
    local shift = 0
    for _, edit in ipairs(edits) do
      if edit.ref_count == 0 then
        if line <= edit.ref_start then
          break
        end
      elseif line < edit.ref_start then
        break
      elseif line < edit.ref_start + edit.ref_count then
        return math.max(
          1,
          math.min(
            line_count,
            edit.buf_start
              + math.min(line - edit.ref_start, math.max(edit.buf_count - 1, 0))
          )
        )
      end
      shift = shift + edit.buf_count - edit.ref_count
    end
    return math.max(1, math.min(line_count, line + shift))
  end
  local result = {}
  for _, hunk in ipairs(hunks) do
    local first = project_line(math.max(hunk.buf_start, 1))
    local last = project_line(
      math.max(hunk.buf_start + hunk.buf_count - 1, hunk.buf_start, 1)
    )
    result[#result + 1] = {
      type = hunk.type,
      buf_start = first,
      buf_count = math.max(last - first + 1, 1),
      ref_start = hunk.ref_start,
      ref_count = hunk.ref_count,
    }
  end
  return result
end

function M.update(buf, effective, line_count, request)
  local cache = require "mini.diff.hunks_cache.staged"
  local snapshot = cache._read(buf)
  if
    not snapshot or (snapshot.status ~= "ready" and not request.staged_ready)
  then
    return
  end
  snapshot.buffer_hunks = M.project(snapshot.hunks, effective, line_count)
  snapshot.version = {
    reference_request = request.request,
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    path = vim.api.nvim_buf_get_name(buf),
  }
  snapshot.status, request.staged_ready = "ready", nil
end

function M.hunks(buf)
  local snapshot = require("mini.diff.hunks_cache.staged")._read(buf)
  return snapshot and snapshot.status == "ready" and snapshot.buffer_hunks or {}
end

return M
