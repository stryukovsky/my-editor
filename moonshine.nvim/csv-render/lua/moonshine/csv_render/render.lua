local M = {}

local function clean(text)
  return text:gsub("\t", "    "):gsub("[%z\1-\8\11-\31\127]", "�")
end

-- Split at word boundaries, then at Unicode characters for unbroken tokens.
-- Whitespace inside a cell is retained; only presentation adds line breaks.
function M.wrap(text, width)
  local result = {}
  for _, paragraph in ipairs(vim.split(clean(text), "\n", { plain = true })) do
    if vim.fn.strdisplaywidth(paragraph) <= width then
      result[#result + 1] = paragraph
    else
      -- split keeps combining marks attached and avoids repeatedly scanning a
      -- long UTF-8 string from the beginning for every character offset.
      local chars = vim.fn.split(paragraph, "\\zs")
      local bytes, byte = {}, 1
      for index, char in ipairs(chars) do
        bytes[index], byte = byte, byte + #char
      end
      bytes[#chars + 1] = byte
      local start, pos, used, space = 1, 1, 0, nil
      while pos <= #chars do
        local char = chars[pos]
        local size = #char == 1 and 1 or vim.fn.strdisplaywidth(char)
        if used + size > width and pos > start then
          local finish = space and space > start and space or pos
          result[#result + 1] = paragraph:sub(bytes[start], bytes[finish] - 1)
          start, pos, used, space = finish, finish, 0, nil
        else
          used, pos = used + size, pos + 1
          if char == " " then
            space = pos
          end
        end
      end
      result[#result + 1] = paragraph:sub(bytes[start])
    end
  end
  return result
end

function M.build(records, available, opts, checkpoint)
  local widths, count = {}, 0
  for index, record in ipairs(records) do
    count = math.max(count, #record.cells)
    for col, cell in ipairs(record.cells) do
      local width = widths[col] or opts.min_column_width
      if width < opts.max_column_width then
        for line in (clean(cell) .. "\n"):gmatch "(.-)\n" do
          width = math.max(
            width,
            math.min(opts.max_column_width, vim.fn.strdisplaywidth(line))
          )
        end
      end
      widths[col] = width
    end
    if checkpoint then
      checkpoint(index)
    end
  end
  if count == 0 then
    return {
      lines = { "(empty CSV)" },
      starts = {},
      widths = {},
      records = records,
    }
  end
  -- Every column has two padding cells, plus a border on either side.
  local fit_width = math.floor((available - count * 3 - 1) / count)
  if count <= opts.fit_columns and fit_width >= opts.min_column_width then
    for col = 1, count do
      widths[col] = fit_width
    end
  end
  local function border(left, middle, right)
    local parts = {}
    for col = 1, count do
      parts[col] = string.rep("─", widths[col] + 2)
    end
    return left .. table.concat(parts, middle) .. right
  end
  local top = border("┌", "┬", "┐")
  local separator = border("├", "┼", "┤")
  local bottom = border("└", "┴", "┘")
  local lines, starts, headers = { top }, {}, {}
  for index, record in ipairs(records) do
    local cells, height = {}, 1
    for col = 1, count do
      cells[col] = M.wrap(record.cells[col] or "", widths[col])
      if index == 1 and #cells[col] > 5 then
        -- Five text lines per heading; keep data cells complete. Truncate by
        -- display cells so wide characters and combining marks stay aligned.
        local prefix, used = {}, 0
        for _, char in ipairs(vim.fn.split(cells[col][5], "\\zs")) do
          local size = vim.fn.strdisplaywidth(char)
          if used + size > widths[col] - 3 then
            break
          end
          prefix[#prefix + 1], used = char, used + size
        end
        cells[col] = { unpack(cells[col], 1, 5) }
        cells[col][5] = table.concat(prefix):gsub("%s+$", "") .. "..."
      end
      height = math.max(height, #cells[col])
    end
    starts[index] = #lines + 1
    for fragment = 1, height do
      local parts = { "│" }
      for col = 1, count do
        local text = cells[col][fragment] or ""
        parts[#parts + 1] = " "
          .. text
          .. string.rep(
            " ",
            math.max(0, widths[col] - vim.fn.strdisplaywidth(text))
          )
          .. " │"
      end
      lines[#lines + 1] = table.concat(parts)
      if index == 1 then
        headers[#headers + 1] = #lines
      end
    end
    lines[#lines + 1] = index == #records and bottom or separator
    if checkpoint then
      checkpoint(index)
    end
  end
  return {
    lines = lines,
    starts = starts,
    widths = widths,
    records = records,
    headers = headers,
  }
end

-- Find the logical record under any content or separator line.
function M.record_at(doc, row)
  local low, high = 1, #doc.starts
  while low < high do
    local mid = math.ceil((low + high) / 2)
    if doc.starts[mid] <= row then
      low = mid
    else
      high = mid - 1
    end
  end
  return low
end

return M
