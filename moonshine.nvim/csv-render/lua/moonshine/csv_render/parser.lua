local M = {}

-- Detect separators only outside quoted fields, including multiline headers.
function M.delimiter(lines, filetype)
  if filetype == "tsv" then
    return "\t"
  end
  local counts = { [","] = 0, [";"] = 0, ["\t"] = 0, ["|"] = 0 }
  local quoted = false
  for _, line in ipairs(lines) do
    local pos = 1
    while pos <= #line do
      local char = line:sub(pos, pos)
      if char == '"' then
        if quoted and line:sub(pos + 1, pos + 1) == '"' then
          pos = pos + 1
        else
          quoted = not quoted
        end
      elseif not quoted and counts[char] then
        counts[char] = counts[char] + 1
      end
      pos = pos + 1
    end
    if not quoted then
      break
    end
  end
  local best = ","
  for _, char in ipairs { ";", "\t", "|" } do
    if counts[char] > counts[best] then
      best = char
    end
  end
  return best
end

-- Parse logical records without converting CSV newlines into display wraps.
-- Positions refer to the original buffer, with 1-based rows and byte columns.
function M.parse(lines, delimiter, checkpoint)
  local records, cells, positions, pieces = {}, {}, {}, {}
  local first, field_row, field_col, quoted, closed = 1, 1, 0, false, false
  local separator = delimiter:byte()
  for row, original in ipairs(lines) do
    local line = original:gsub("\r$", "")
    local pos = row == 1 and line:sub(1, 3) == "\239\187\191" and 4 or 1
    if row == 1 then
      field_col = pos - 1
    end
    local start = pos
    local function finish_field()
      pieces[#pieces + 1] = line:sub(start, pos - 1)
      cells[#cells + 1] = table.concat(pieces)
      positions[#positions + 1] = { field_row, field_col }
      pieces, closed = {}, false
    end
    while pos <= #line do
      local byte = line:byte(pos)
      if quoted then
        if byte == 34 then
          pieces[#pieces + 1] = line:sub(start, pos - 1)
          if line:byte(pos + 1) == 34 then
            pieces[#pieces + 1] = '"'
            pos = pos + 2
          else
            quoted, closed = false, true
            pos = pos + 1
          end
          start = pos
        else
          pos = pos + 1
        end
      elseif byte == separator then
        finish_field()
        pos = pos + 1
        start, field_row, field_col = pos, row, pos - 1
      elseif byte == 34 and pos == start and #pieces == 0 and not closed then
        quoted = true
        pos = pos + 1
        start = pos
      elseif byte == 34 or (closed and byte ~= 32 and byte ~= 9) then
        error("Invalid CSV quoting at source line " .. row, 0)
      else
        pos = pos + 1
      end
    end
    if quoted then
      pieces[#pieces + 1] = line:sub(start) .. "\n"
    else
      finish_field()
      records[#records + 1] =
        { cells = cells, positions = positions, first = first, last = row }
      cells, positions = {}, {}
      first, field_row, field_col = row + 1, row + 1, 0
    end
    if checkpoint then
      checkpoint(row)
    end
  end
  if quoted then
    error("Unclosed quoted CSV field starting at source line " .. field_row, 0)
  end
  return records
end

return M
