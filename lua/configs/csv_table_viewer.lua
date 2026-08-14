-- CSV/TSV row viewer
-- Opens the current row in a floating window, optionally labeled by header cells.
-- On close (q / Esc / leave), writes edited values back into the source buffer line.
-- Renames of ## column labels in the float are ignored; only values are written back.
-- From the float, `n` / M.next() applies edits and previews the next data row.

local M = {}
local notify = require "configs.notify"
local map = require "mappings.map"

-- Sentinel so empty cells survive blank-line-separated plain round-trips.
local EMPTY_CELL = "␀"

local COMMENT_PREFIXES = { "#", "//" }

---@type { go_next: fun() }|nil
local active = nil

---@return string
local function delimiter()
  if vim.bo.filetype == "tsv" then
    return "\t"
  end
  return ","
end

---@param line string
---@return boolean
local function is_comment(line)
  local trimmed = vim.trim(line)
  if trimmed == "" then
    return false
  end
  for _, prefix in ipairs(COMMENT_PREFIXES) do
    if trimmed:sub(1, #prefix) == prefix then
      return true
    end
  end
  return false
end

---@param line string
---@return boolean
local function is_data_row(line)
  return vim.trim(line) ~= "" and not is_comment(line)
end

---RFC 4180-style split. Quotes inside quotes are doubled ("").
---@param line string
---@param delim string
---@return string[]
local function parse_cells(line, delim)
  local cells = {}
  local current = {}
  local i = 1
  local in_quotes = false

  while i <= #line do
    local ch = line:sub(i, i)
    if in_quotes then
      if ch == '"' then
        if line:sub(i + 1, i + 1) == '"' then
          current[#current + 1] = '"'
          i = i + 2
        else
          in_quotes = false
          i = i + 1
        end
      else
        current[#current + 1] = ch
        i = i + 1
      end
    elseif ch == '"' then
      in_quotes = true
      i = i + 1
    elseif ch == delim then
      table.insert(cells, table.concat(current))
      current = {}
      i = i + 1
    else
      current[#current + 1] = ch
      i = i + 1
    end
  end
  table.insert(cells, table.concat(current))
  return cells
end

---@param value string
---@param delim string
---@return string
local function escape_field(value, delim)
  local needs_quote = value:find('"', 1, true)
    or value:find("\n", 1, true)
    or value:find("\r", 1, true)
    or value:find(delim, 1, true)
    or value:match "^%s"
    or value:match "%s$"
  if needs_quote then
    return '"' .. value:gsub('"', '""') .. '"'
  end
  return value
end

---@param buf integer
---@return integer|nil 1-based header line
local function find_header_row(buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  for r = 1, line_count do
    local line = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1]
    if line and is_data_row(line) then
      return r
    end
  end
end

---@param buf integer
---@param row integer 1-based
---@param delim string
---@return string[]|nil
local function find_header_cells(buf, row, delim)
  local header_row = find_header_row(buf)
  if not header_row or header_row == row then
    return nil
  end
  local line = vim.api.nvim_buf_get_lines(buf, header_row - 1, header_row, false)[1]
  if not line then
    return nil
  end
  return parse_cells(line, delim)
end

---@param buf integer
---@param row integer 1-based
---@return integer|nil
local function find_next_data_row(buf, row)
  local line_count = vim.api.nvim_buf_line_count(buf)
  for r = row + 1, line_count do
    local line = vim.api.nvim_buf_get_lines(buf, r - 1, r, false)[1]
    if line and is_data_row(line) then
      return r
    end
  end
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
  return (text:gsub("%s*\n%s*", " "))
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
---@param delim string
---@return string
local function format_row(cells, delim)
  local out = {}
  for i, cell in ipairs(cells) do
    out[i] = escape_field(cell, delim)
  end
  return table.concat(out, delim)
end

---@param ctx { source_buf: integer, source_row: integer, original_line: string, has_headers: boolean, col_count: integer, delim: string }
---@param float_buf integer
local function apply_edits(ctx, float_buf)
  if not vim.api.nvim_buf_is_valid(ctx.source_buf) then
    notify.send("CSV row", "Source buffer is gone; edits discarded", vim.log.levels.WARN)
    return
  end
  if not vim.api.nvim_buf_is_valid(float_buf) then
    notify.send("CSV row", "View buffer was wiped before apply; edits discarded", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
  local cells = ctx.has_headers and parse_headed_content(lines) or parse_plain_content(lines)
  cells = normalize_cell_count(cells, ctx.col_count)

  local new_line = format_row(cells, ctx.delim)
  if new_line == ctx.original_line then
    return
  end

  local row0 = ctx.source_row - 1
  local line_count = vim.api.nvim_buf_line_count(ctx.source_buf)
  if row0 < 0 or row0 >= line_count then
    notify.send("CSV row", "Source row no longer exists; edits discarded", vim.log.levels.WARN)
    return
  end

  local current = vim.api.nvim_buf_get_lines(ctx.source_buf, row0, row0 + 1, false)[1]
  if current ~= ctx.original_line then
    notify.send("CSV row", "Source row changed while editing; edits discarded", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_buf_set_lines(ctx.source_buf, row0, row0 + 1, false, { new_line })
end

---@param content string[]
---@param ctx { source_buf: integer, source_win: integer, source_row: integer, original_line: string, has_headers: boolean, col_count: integer, is_heading: boolean, delim: string }
local function open_float(content, ctx)
  local buf = vim.api.nvim_create_buf(false, true)
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
    title = ctx.is_heading and "Headers of CSV" or "CSV row",
    title_pos = "center",
  })
  vim.wo.wrap = true

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
    local next_row = find_next_data_row(ctx.source_buf, ctx.source_row)
    teardown()
    if not next_row then
      notify.send("CSV row", "No next CSV row", vim.log.levels.INFO)
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

  map("n", "q", close, { buffer = buf, nowait = true, silent = true, desc = "Close CSV row view" })
  map("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true, desc = "Close CSV row view" })
  map("n", "n", go_next, { buffer = buf, nowait = true, silent = true, desc = "Next CSV row" })

  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = buf,
    callback = close,
  })
end

--- View the CSV/TSV row under the cursor in a floating window.
function M.view_row()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
  local delim = delimiter()

  if not line or not is_data_row(line) then
    notify.send("CSV row", "Not a CSV data row", vim.log.levels.WARN)
    return
  end

  local values = parse_cells(line, delim)
  if #values == 0 then
    notify.send("CSV row", "Not a CSV data row", vim.log.levels.WARN)
    return
  end

  local header_row = find_header_row(buf)
  local heading = header_row == row
  local headers = find_header_cells(buf, row, delim)
  local ctx = {
    source_buf = buf,
    source_win = win,
    source_row = row,
    original_line = line,
    has_headers = headers ~= nil,
    col_count = headers and math.max(#headers, #values) or #values,
    is_heading = heading,
    delim = delim,
  }
  open_float(build_content(values, headers), ctx)
end

--- Preview the next CSV row (applies float edits first when a view is open).
function M.next()
  if active then
    active.go_next()
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local next_row = find_next_data_row(buf, row)
  if not next_row then
    notify.send("CSV row", "No next CSV row", vim.log.levels.WARN)
    return
  end

  vim.api.nvim_win_set_cursor(0, { next_row, 0 })
  M.view_row()
end

return M
