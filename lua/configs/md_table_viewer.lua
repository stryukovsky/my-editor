-- Markdown table row viewer
-- Opens the current table row in a floating window, optionally labeled by header cells.
-- On close (q / Esc / leave), writes edited values back into the source buffer line.
-- Renames of ## column labels in the float are ignored; only values are written back.
-- From the float, `n` / M.next() applies edits and previews the next data row.

local M = {}
local notify = require "configs.notify"
local map = require "mappings.map"

-- Sentinel so empty cells survive blank-line-separated plain round-trips.
local EMPTY_CELL = "␀"

---@type { go_next: fun() }|nil
local active = nil

---@param line string
---@return boolean
local function is_separator(line)
  local trimmed = vim.trim(line)
  if trimmed == "" or not trimmed:find "|" or not trimmed:find "%-" then
    return false
  end
  -- Only pipes, dashes, colons, spaces (GFM delimiter row).
  return trimmed:match "^|?[%-%s:|]+|?$" ~= nil
end

---@param line string
---@return boolean
local function is_table_row(line)
  local trimmed = vim.trim(line)
  if trimmed == "" or is_separator(trimmed) then
    return false
  end
  -- Row with leading pipe, or cells separated by pipes.
  return trimmed:match "^|" ~= nil or trimmed:match ".+|.+" ~= nil
end

---@param buf integer
---@param row integer 1-based
---@return boolean
local function is_header_row(buf, row)
  local next_line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  return next_line ~= nil and is_separator(next_line)
end

---Next data/header row after `row` in the same table (skips the GFM separator).
---@param buf integer
---@param row integer 1-based
---@return integer|nil
local function find_next_table_row(buf, row)
  local line_count = vim.api.nvim_buf_line_count(buf)
  local r = row + 1
  while r <= line_count do
    local line = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1]
    if not line or vim.trim(line) == "" then
      return nil
    end
    if is_separator(line) then
      r = r + 1
    elseif is_table_row(line) then
      return r
    else
      return nil
    end
  end
  return nil
end

---Split a table row into cells. Pipes inside inline code (`...`, including `|`) are not delimiters.
---@param line string
---@return string[]
local function parse_cells(line)
  local trimmed = vim.trim(line)
  local start = 1
  local finish = #trimmed
  if trimmed:sub(1, 1) == "|" then
    start = 2
  end
  if trimmed:sub(-1) == "|" then
    finish = finish - 1
  end
  local body = trimmed:sub(start, finish)

  local cells = {}
  local current = {}
  local i = 1
  local in_code = false

  while i <= #body do
    local ch = body:sub(i, i)
    if ch == "`" then
      in_code = not in_code
      current[#current + 1] = ch
      i = i + 1
    elseif ch == "|" and not in_code then
      table.insert(cells, vim.trim(table.concat(current)))
      current = {}
      i = i + 1
    else
      current[#current + 1] = ch
      i = i + 1
    end
  end
  table.insert(cells, vim.trim(table.concat(current)))
  return cells
end

---@param buf integer
---@param row integer 1-based line number of the current row
---@return string[]|nil header cells, or nil if cursor is on the header / none found
local function find_header_cells(buf, row)
  -- Cursor is already on the header row (next line is the separator).
  if is_header_row(buf, row) then
    return nil
  end

  for r = row - 1, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1]
    if not line or vim.trim(line) == "" then
      break
    end
    if is_separator(line) then
      if r > 1 then
        local header_line = vim.api.nvim_buf_get_lines(buf, r - 2, r - 1, false)[1]
        if header_line and is_table_row(header_line) then
          return parse_cells(header_line)
        end
      end
      return nil
    end
    if not is_table_row(line) then
      break
    end
  end

  return nil
end

---@param value string
---@return string
local function display_value(value)
  if value == "" then
    return EMPTY_CELL
  end
  return value
end

---@param value string
---@return string
local function storage_value(value)
  local text = vim.trim(value)
  if text == EMPTY_CELL or text == "" then
    return ""
  end
  -- Pipe-table cells are single-line.
  -- Parentheses: gsub returns (str, n); without them table.insert sees 3 args.
  return (text:gsub("%s*\n%s*", " "))
end
---Ensure bare `|` characters are wrapped as inline code so they are not cell delimiters.
---@param cell string
---@return string
local function protect_pipes(cell)
  local out = {}
  local i = 1
  local in_code = false

  while i <= #cell do
    local ch = cell:sub(i, i)
    if ch == "`" then
      in_code = not in_code
      out[#out + 1] = ch
      i = i + 1
    elseif ch == "|" and not in_code then
      out[#out + 1] = "`|`"
      i = i + 1
    else
      out[#out + 1] = ch
      i = i + 1
    end
  end

  return table.concat(out)
end

---@param values string[]
---@param headers string[]|nil
---@return string[]
local function build_content(values, headers)
  local lines = {}
  if headers then
    local n = math.max(#headers, #values)
    for i = 1, n do
      if i > 1 then
        table.insert(lines, "")
      end
      -- Labels only: renames of these ## lines are ignored on write-back.
      table.insert(lines, "## " .. (headers[i] or ("Column " .. i)))
      table.insert(lines, display_value(values[i] or ""))
    end
  else
    for i, value in ipairs(values) do
      if i > 1 then
        table.insert(lines, "")
      end
      table.insert(lines, display_value(value))
    end
  end
  return lines
end

---Parse float buffer opened with headers (## name / value blocks).
---Heading text after ## is ignored; only the value lines become cells.
---@param lines string[]
---@return string[]
local function parse_headed_content(lines)
  local cells = {}
  local current ---@type string[]|nil

  local function flush()
    if not current then
      return
    end
    table.insert(cells, storage_value(table.concat(current, "\n")))
    current = nil
  end

  for _, line in ipairs(lines) do
    -- Only ## headers are structural; "# foo" inside a value stays in the cell.
    if line:match "^##%s+" then
      flush()
      current = {}
    elseif current then
      table.insert(current, line)
    end
  end
  flush()
  return cells
end

---Parse float buffer opened without headers (blank-line-separated values).
---@param lines string[]
---@return string[]
local function parse_plain_content(lines)
  local cells = {}
  local current = {}

  local function flush()
    if #current == 0 then
      return
    end
    table.insert(cells, storage_value(table.concat(current, "\n")))
    current = {}
  end

  for _, line in ipairs(lines) do
    if line == "" then
      flush()
    else
      table.insert(current, line)
    end
  end
  flush()
  return cells
end

---@param cells string[]
---@param col_count integer
---@return string[]
local function normalize_cell_count(cells, col_count)
  local out = {}
  for i = 1, col_count do
    out[i] = cells[i] or ""
  end
  return out
end

---@param cells string[]
---@param original_line string
---@return string
local function format_row(cells, original_line)
  local trimmed = vim.trim(original_line)
  local leading = trimmed:match "^|" ~= nil
  local trailing = trimmed:match "|$" ~= nil

  local protected = {}
  for i, cell in ipairs(cells) do
    protected[i] = protect_pipes(cell)
  end

  local body = table.concat(protected, " | ")
  if leading and trailing then
    return "| " .. body .. " |"
  elseif leading then
    return "| " .. body
  elseif trailing then
    return body .. " |"
  end
  return body
end

---@param ctx { source_buf: integer, source_row: integer, original_line: string, has_headers: boolean, col_count: integer }
---@param float_buf integer
local function apply_edits(ctx, float_buf)
  if not vim.api.nvim_buf_is_valid(ctx.source_buf) then
    notify.send("Table row", "Source buffer is gone; edits discarded", vim.log.levels.WARN)
    return
  end
  if not vim.api.nvim_buf_is_valid(float_buf) then
    notify.send("Table row", "View buffer was wiped before apply; edits discarded", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
  -- Header label renames (## ...) are ignored here by design.
  local cells = ctx.has_headers and parse_headed_content(lines) or parse_plain_content(lines)
  cells = normalize_cell_count(cells, ctx.col_count)

  local new_line = format_row(cells, ctx.original_line)
  if new_line == ctx.original_line then
    return
  end

  local row0 = ctx.source_row - 1
  local line_count = vim.api.nvim_buf_line_count(ctx.source_buf)
  if row0 < 0 or row0 >= line_count then
    notify.send("Table row", "Source row no longer exists; edits discarded", vim.log.levels.WARN)
    return
  end

  -- Refuse to clobber a line that is no longer the table row we opened.
  local current = vim.api.nvim_buf_get_lines(ctx.source_buf, row0, row0 + 1, false)[1]
  if current ~= ctx.original_line then
    notify.send("Table row", "Source row changed while editing; edits discarded", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(ctx.source_buf, row0, row0 + 1, false, { new_line })
end

---@param content string[]
---@param ctx { source_buf: integer, source_win: integer, source_row: integer, original_line: string, has_headers: boolean, col_count: integer, is_heading: boolean }
local function open_float(content, ctx)
  local buf = vim.api.nvim_create_buf(false, true)
  -- Keep buffer until we finish apply on leave; wipe afterward.
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = true
  vim.bo[buf].modified = false

  local max_width = 0
  for _, line in ipairs(content) do
    max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
  end

  local width = math.max(20, math.min(max_width + 2, math.floor(vim.o.columns * 0.8)))
  local height = math.max(1, math.min(#content, math.floor(vim.o.lines * 0.6)))

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "single",
    title = ctx.is_heading and "Headers of table" or "Table row",
    title_pos = "center",
  })

  local closed = false

  local function teardown()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_close, win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
  end

  local function close()
    if closed then
      return
    end
    closed = true
    active = nil
    -- Apply synchronously while float buf is still valid (leave+schedule used to wipe first).
    apply_edits(ctx, buf)
    teardown()
  end

  local function go_next()
    if closed then
      return
    end
    closed = true
    active = nil
    apply_edits(ctx, buf)
    local next_row = find_next_table_row(ctx.source_buf, ctx.source_row)
    teardown()
    if not next_row then
      notify.send("Table row", "No next table row", vim.log.levels.INFO)
      return
    end
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ctx.source_buf) then
        return
      end
      if vim.api.nvim_win_is_valid(ctx.source_win) then
        vim.api.nvim_set_current_win(ctx.source_win)
        vim.api.nvim_win_set_cursor(ctx.source_win, { next_row, 0 })
      end
      M.view_row()
    end)
  end

  active = { go_next = go_next }

  map("n", "q", close, { buffer = buf, nowait = true, silent = true, desc = "Close table row view" })
  map("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true, desc = "Close table row view" })
  map("n", "n", go_next, { buffer = buf, nowait = true, silent = true, desc = "Next table row" })

  -- Apply on leave immediately; do not schedule (buffer can be gone by then).
  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = buf,
    callback = close,
  })
end

--- View the markdown table row under the cursor in a floating window.
function M.view_row()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]

  if not line or not is_table_row(line) then
    notify.send("Table row", "Not a markdown table row", vim.log.levels.WARN)
    return
  end

  local values = parse_cells(line)
  if #values == 0 then
    notify.send("Table row", "Not a markdown table row", vim.log.levels.WARN)
    return
  end

  local heading = is_header_row(buf, row)
  local headers = find_header_cells(buf, row)
  local ctx = {
    source_buf = buf,
    source_win = win,
    source_row = row,
    original_line = line,
    has_headers = headers ~= nil,
    col_count = headers and math.max(#headers, #values) or #values,
    is_heading = heading,
  }
  open_float(build_content(values, headers), ctx)
end

--- Preview the next table row (applies float edits first when a view is open).
function M.next()
  if active then
    active.go_next()
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local next_row = find_next_table_row(buf, row)
  if not next_row then
    notify.send("Table row", "No next table row", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_win_set_cursor(0, { next_row, 0 })
  M.view_row()
end

return M
