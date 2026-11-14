-- Pure staged snapshot helpers. Index hunks remain separate from display anchors.
local M = {}

function M.parse(patch)





  local hunks = {}
  for line in patch:gmatch("[^\n]+") do
    -- Only unprefixed metadata can classify a patch. Source lines may contain
    -- these exact strings behind their +/-/context prefix.
    if line:match("^Binary files .* differ$") or line == "GIT binary patch" then
      return nil, "Binary staged diff is unavailable"
    end
    if line:match("^%* Unmerged path ") or line:match("^diff %-%-cc ") or line:match("^diff %-%-combined ") then
      return nil, "Unmerged index entries are unsupported"
    end
    local old, old_count, new, new_count = line:match("^@@ %-(%d+)(,?%d*) %+(%d+)(,?%d*) @@")
    if old then
      old_count = old_count == "" and 1 or tonumber(old_count:sub(2))
      new_count = new_count == "" and 1 or tonumber(new_count:sub(2))
      hunks[#hunks + 1] = {
        ref_start = tonumber(old),
        ref_count = old_count,
        buf_start = tonumber(new),
        buf_count = new_count,
        type = old_count == 0 and "add" or (new_count == 0 and "delete" or "change"),
      }
    end
  end
  return hunks
end

-- Map index lines through index -> buffer edits. Removed spans use their
-- replacement (or the preceding surviving line) as a reachable display anchor.
function M.project(hunks, edits, line_count)
  local function project_line(line)
    local shift = 0
    for _, edit in ipairs(edits) do
      if edit.ref_count == 0 then
        if line <= edit.ref_start then break end
      elseif line < edit.ref_start then
        break
      elseif line < edit.ref_start + edit.ref_count then
        return math.max(1, math.min(line_count, edit.buf_start + math.min(line - edit.ref_start, math.max(edit.buf_count - 1, 0))))
      end
      shift = shift + edit.buf_count - edit.ref_count
    end
    return math.max(1, math.min(line_count, line + shift))
  end
  local result = {}
  for _, hunk in ipairs(hunks) do
    local first = project_line(math.max(hunk.buf_start, 1))
    local last = project_line(math.max(hunk.buf_start + hunk.buf_count - 1, hunk.buf_start, 1))
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

return M
