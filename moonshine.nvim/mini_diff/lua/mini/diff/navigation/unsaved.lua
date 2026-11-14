local M = {}

-- Route only effective index -> buffer hunks. Raw unsaved edits can explain a
-- target, but cannot resurrect edits cancelled by saved working-tree changes.
function M.partition(buf, effective)
  local snapshot = require("mini.diff.hunks_cache.unsaved")._read(buf)
  local saved, unsaved = {}, {}
  local current = snapshot
    and snapshot.status == "ready"
    and snapshot.version
    and snapshot.version.changedtick == vim.api.nvim_buf_get_changedtick(buf)
  local edits, index = current and snapshot.hunks or {}, 1
  for _, hunk in ipairs(effective) do
    local from, to =
      math.max(hunk.buf_start, 1),
      math.max(hunk.buf_start, 1) + math.max(hunk.buf_count, 1) - 1
    -- Both edit lists are buffer-ordered. Avoid a quadratic statusline scan.
    while edits[index] do
      local edit = edits[index]
      if
        math.max(edit.buf_start, 1) + math.max(edit.buf_count, 1) - 1 >= from
      then
        break
      end
      index = index + 1
    end
    local dirty = edits[index] and math.max(edits[index].buf_start, 1) <= to
    local target = dirty and unsaved or saved
    target[#target + 1] = hunk
  end
  return saved, unsaved
end

return M
