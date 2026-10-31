local M = {}

-- All columns here are byte offsets. LSP positions are converted at this edge.
function M.keyword(line, col)
  return vim.fn.matchstr(line:sub(1, col), [[\k*$]])
end

function M.get(state, item, client)
  local base = state.keyword or M.keyword(state.line, state.col)
  local start = state.col - #base
  local edit = item.textEdit
  if type(edit) == "table" then
    local range = edit.insert or edit.range
    local pos = range and range.start
    if not pos or pos.line ~= state.row or type(pos.character) ~= "number" then
      return nil
    end
    local ok, byte = pcall(
      vim.str_byteindex,
      state.line,
      client and client.offset_encoding or "utf-16",
      pos.character,
      true
    )
    if not ok or byte > state.col or byte < 0 then
      return nil
    end
    start = byte
    base = state.line:sub(start + 1, state.col)
    -- A qualified edit can replace the receiver too, while filterText is a name.
    local filter = item.filterText or item.label or ""
    if
      base:find "[.:]"
      and not vim.startswith(filter, base:match "^.*[.:]" or "")
    then
      base = M.keyword(state.line, state.col)
      start = state.col - #base
    end
  end
  return base, start
end

return M
