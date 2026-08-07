-- Markdown table row viewer
-- Opens the current table row in a floating window, optionally labeled by header cells.

local M = {}
local notify = require "configs.notify"
local map = require "mappings.map"

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

---@param line string
---@return string[]
local function parse_cells(line)
  local trimmed = vim.trim(line)
  trimmed = trimmed:gsub("^|", ""):gsub("|$", "")
  local cells = {}
  for cell in vim.gsplit(trimmed, "|", { plain = true }) do
    table.insert(cells, vim.trim(cell))
  end
  return cells
end

---@param buf integer
---@param row integer 1-based line number of the current row
---@return string[]|nil header cells, or nil if cursor is on the header / none found
local function find_header_cells(buf, row)
  local next_line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  -- Cursor is already on the header row (next line is the separator).
  if next_line and is_separator(next_line) then
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
      table.insert(lines, "# " .. (headers[i] or ("Column " .. i)))
      table.insert(lines, values[i] or "")
    end
  else
    for i, value in ipairs(values) do
      if i > 1 then
        table.insert(lines, "")
      end
      table.insert(lines, value)
    end
  end
  return lines
end

---@param content string[]
---@return integer win
local function open_float(content)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
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
    title = "Table row",
    title_pos = "center",
  })

  local closed = false
  local function close()
    if closed then
      return
    end
    closed = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    elseif vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end

  map("n", "q", close, { buffer = buf, nowait = true, silent = true, desc = "Close table row view" })
  map("n", "<Esc>", close, { buffer = buf, nowait = true, silent = true, desc = "Close table row view" })

  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = buf,
    callback = function()
      vim.schedule(close)
    end,
  })

  return win
end

--- View the markdown table row under the cursor in a floating window.
function M.view_row()
  local buf = vim.api.nvim_get_current_buf()
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

  local headers = find_header_cells(buf, row)
  open_float(build_content(values, headers))
end

return M
