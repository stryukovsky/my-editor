local map = require "mappings.map"

local function is_http_buffer()
  return vim.api.nvim_buf_get_name(0):match("%.http$") ~= nil
end

local function count_consecutive_blanks(lines, start, step)
  local count = 0
  local i = start
  while i >= 1 and i <= #lines and lines[i] == "" do
    count = count + 1
    i = i + step
  end
  return count
end

local function find_block(lines, cursor_line)
  local n = #lines

  local block_start = 1
  local i = cursor_line - 1
  while i >= 1 do
    if lines[i]:match("^###") then
      block_start = i + 1
      break
    elseif lines[i] == "" then
      if count_consecutive_blanks(lines, i, -1) >= 2 then
        block_start = i + 1
        break
      end
    end
    i = i - 1
  end

  local block_end = n
  i = cursor_line + 1
  while i <= n do
    if lines[i]:match("^###") then
      block_end = i - 1
      break
    elseif lines[i] == "" then
      if count_consecutive_blanks(lines, i, 1) >= 2 then
        block_end = i - 1
        break
      end
    end
    i = i + 1
  end

  return block_start, block_end
end

local function parse_request(lines, start_line, end_line)
  local method, url, headers, body_lines
  local in_body = false

  for i = start_line, end_line do
    local line = lines[i]

    if line:match("^#") then
    elseif not method then
      method, url = line:match("^(%S+)%s+(%S+)")
    elseif in_body then
      table.insert(body_lines, line)
    elseif line == "" then
      in_body = true
      body_lines = {}
    else
      local key, value = line:match("^([%w%-]+):%s*(.+)")
      if key then
        if not headers then
          headers = {}
        end
        headers[key] = value
      end
    end
  end

  return {
    method = method and method:upper() or "GET",
    url = url,
    headers = headers,
    body = body_lines and #body_lines > 0 and table.concat(body_lines, "\n") or nil,
  }
end

local function execute(req)
  local ok, curl = pcall(require, "plenary.curl")
  if not ok then
    vim.notify("plenary.nvim not available", vim.log.levels.ERROR)
    return
  end

  local fn = curl[req.method:lower()]
  if not fn then
    vim.notify("Unsupported method: " .. req.method, vim.log.levels.ERROR)
    return
  end

  local opts = {}
  if req.body then
    opts.body = req.body
  end
  if req.headers then
    opts.headers = req.headers
  end

  local ok2, res = pcall(fn, req.url, opts)
  if not ok2 then
    vim.notify("Request failed: " .. tostring(res), vim.log.levels.ERROR)
    return
  end
  return res
end

local function show_response(res)
  if not res then
    return
  end

  vim.cmd("rightbelow vsplit")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)

  local content = {}
  table.insert(content, "Status: " .. (res.status or "?"))
  table.insert(content, "")
  if res.headers then
    for _, h in ipairs(res.headers) do
      table.insert(content, h)
    end
    table.insert(content, "")
  end
  if res.body then
    vim.list_extend(content, vim.split(res.body, "\n", { plain = true }))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modified = false
  vim.bo[buf].filetype = "http-response"
end

map("n", "<leader>rq", function()
  if not is_http_buffer() then
    vim.notify("Not a .http file", vim.log.levels.WARN)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] + 1

  if cursor_line < 1 or cursor_line > #lines then
    return
  end

  local current_line = lines[cursor_line]
  if current_line == "" or current_line:match("^###") then
    vim.notify("No request at cursor position", vim.log.levels.WARN)
    return
  end

  local start_line, end_line = find_block(lines, cursor_line)
  local req = parse_request(lines, start_line, end_line)

  if not req.url then
    vim.notify("No valid METHOD URL in request block", vim.log.levels.WARN)
    return
  end

  local res = execute(req)
  show_response(res)
end, { desc = "Execute HTTP request under cursor" })
