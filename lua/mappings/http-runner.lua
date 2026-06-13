local map = require "mappings.map"

local function is_http_buffer()
  local name = vim.api.nvim_buf_get_name(0)
  local ok = name:match("%.http$") ~= nil
  vim.notify("http-runner: buffer name='" .. name .. "', is_http=" .. tostring(ok), vim.log.levels.DEBUG)
  return ok
end

local function get_line(buf, row)
  return vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
end

local function count_consecutive_blanks(lines, start, step)
  local count = 0
  local i = start + 1
  while i >= 1 and i <= #lines and lines[i] == "" do
    count = count + 1
    i = i + step
  end
  return count
end

local function find_block(buf, lines, cursor_row)
  local n = #lines
  vim.notify(
    "http-runner: find_block total_lines=" .. n .. " cursor_row(0-idx)=" .. cursor_row,
    vim.log.levels.DEBUG
  )

  local block_start = 0
  local i = cursor_row - 1
  while i >= 0 do
    local line = get_line(buf, i)
    vim.notify(
      "http-runner: backward scan row=" .. i .. " line='" .. (line or "nil") .. "'",
      vim.log.levels.DEBUG
    )
    if line and line:match("^###") then
      block_start = i + 1
      vim.notify("http-runner: found ### at row " .. i .. ", block_start=" .. block_start, vim.log.levels.DEBUG)
      break
    elseif line == "" then
      local blanks = count_consecutive_blanks(lines, i, -1)
      vim.notify("http-runner: blanks backward from row " .. i .. " = " .. blanks, vim.log.levels.DEBUG)
      if blanks >= 2 then
        block_start = i + 1
        vim.notify("http-runner: 2+ blanks at row " .. i .. ", block_start=" .. block_start, vim.log.levels.DEBUG)
        break
      end
    end
    i = i - 1
  end

  local block_end = n - 1
  i = cursor_row + 1
  while i < n do
    local line = get_line(buf, i)
    vim.notify(
      "http-runner: forward scan row=" .. i .. " line='" .. (line or "nil") .. "'",
      vim.log.levels.DEBUG
    )
    if line and line:match("^###") then
      block_end = i - 1
      vim.notify("http-runner: found ### at row " .. i .. ", block_end=" .. block_end, vim.log.levels.DEBUG)
      break
    elseif line == "" then
      local blanks = count_consecutive_blanks(lines, i, 1)
      vim.notify("http-runner: blanks forward from row " .. i .. " = " .. blanks, vim.log.levels.DEBUG)
      if blanks >= 2 then
        block_end = i - 1
        vim.notify("http-runner: 2+ blanks at row " .. i .. ", block_end=" .. block_end, vim.log.levels.DEBUG)
        break
      end
    end
    i = i + 1
  end

  vim.notify(
    "http-runner: block range (0-idx) " .. block_start .. " -> " .. block_end,
    vim.log.levels.DEBUG
  )

  if block_start > block_end then
    vim.notify(
      "http-runner: empty block (start " .. block_start .. " > end " .. block_end .. ")",
      vim.log.levels.WARN
    )
    return nil
  end

  return block_start, block_end
end

local function urlencode(s)
  return (tostring(s):gsub("([^%w%.%-_~])", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

local function header_value(headers, name)
  if not headers then return nil end
  for k, v in pairs(headers) do
    if k:lower() == name:lower() then return v end
  end
  return nil
end

local function parse_request(buf, lines, start_row, end_row)
  local method, url, headers, params, body_lines
  local in_body = false
  local body_is_json = false

  vim.notify(
    "http-runner: parsing rows (0-idx) " .. start_row .. "-" .. end_row,
    vim.log.levels.DEBUG
  )

  for row = start_row, end_row do
    local line = get_line(buf, row)
    vim.notify(
      "http-runner:  parse row " .. row .. " in_body=" .. tostring(in_body) .. " '" .. (line or "nil") .. "'",
      vim.log.levels.DEBUG
    )

    if not line then
      vim.notify("http-runner:  -> nil line (skip)", vim.log.levels.DEBUG)
    elseif line:match("^#") then
      vim.notify("http-runner:  -> comment (skip)", vim.log.levels.DEBUG)
    elseif not method then
      method, url = line:match("^(%S+)%s+(%S+)")
      if method then
        vim.notify(
          "http-runner:  -> method='" .. method .. "' url='" .. (url or "nil") .. "'",
          vim.log.levels.DEBUG
        )
      else
        vim.notify(
          "http-runner:  -> not a METHOD URL line (no match)",
          vim.log.levels.DEBUG
        )
      end
    elseif in_body then
      if not body_is_json then
        local trimmed = line:match("^%s*(.-)%s*$")
        if trimmed and trimmed ~= "" then
          if trimmed:sub(1, 1) == "{" then
            body_is_json = true
            vim.notify("http-runner:  -> body is JSON", vim.log.levels.DEBUG)
          end
        end
      end
      if body_is_json then
        table.insert(body_lines, line)
        vim.notify("http-runner:  -> body line", vim.log.levels.DEBUG)
      else
        local pkey, pval = line:match("^([%w%.%-_]+)=(.+)$")
        if pkey then
          if not params then params = {} end
          params[pkey] = pval
          vim.notify("http-runner:  -> body param " .. pkey .. "=" .. pval, vim.log.levels.DEBUG)
        else
          table.insert(body_lines, line)
          vim.notify("http-runner:  -> body line (non-param)", vim.log.levels.DEBUG)
        end
      end
    elseif line == "" then
      in_body = true
      body_lines = {}
      vim.notify("http-runner:  -> blank line, switching to body", vim.log.levels.DEBUG)
    else
      local key, value = line:match("^([%w%-]+):%s*(.+)")
      if key then
        if not headers then
          headers = {}
        end
        headers[key] = value
        vim.notify(
          "http-runner:  -> header " .. key .. ": " .. value,
          vim.log.levels.DEBUG
        )
      else
        local pkey, pval = line:match("^([%w%.%-_]+)=(.+)$")
        if pkey then
          if not params then params = {} end
          params[pkey] = pval
          vim.notify(
            "http-runner:  -> param " .. pkey .. "=" .. pval,
            vim.log.levels.DEBUG
          )
        else
          vim.notify(
            "http-runner:  -> unrecognized line (not header/param/blank/method/comment)",
            vim.log.levels.DEBUG
          )
        end
      end
    end
  end

  local body = body_lines and #body_lines > 0 and table.concat(body_lines, "\n") or nil
  vim.notify(
    "http-runner: parsed method=" .. (method or "GET (default)")
      .. " url=" .. (url or "nil")
      .. " headers=" .. vim.inspect(headers)
      .. " params=" .. vim.inspect(params)
      .. " body=" .. (body and #body > 0 and #body .. " chars" or "nil")
      .. " body_is_json=" .. tostring(body_is_json),
    vim.log.levels.DEBUG
  )

  return {
    method = method and method:upper() or "GET",
    url = url,
    headers = headers,
    params = params,
    body = body,
  }
end

local function execute(req)
  vim.notify(
    "http-runner: executing " .. req.method .. " " .. (req.url or "nil"),
    vim.log.levels.INFO
  )

  local ok, curl = pcall(require, "plenary.curl")
  if not ok then
    vim.notify(
      "http-runner: failed to require plenary.curl: " .. tostring(curl),
      vim.log.levels.ERROR
    )
    return
  end
  vim.notify("http-runner: plenary.curl loaded", vim.log.levels.DEBUG)

  local fn = curl[req.method:lower()]
  if not fn then
    vim.notify(
      "http-runner: unsupported method '" .. req.method .. "', available: "
        .. vim.inspect(vim.tbl_keys(curl)),
      vim.log.levels.ERROR
    )
    return
  end

  local opts = {}

  if req.method == "GET" and req.params then
    opts.query = req.params
    vim.notify("http-runner: using params as query: " .. vim.inspect(req.params), vim.log.levels.DEBUG)
    if req.headers then
      opts.headers = req.headers
    end

  elseif req.body then
    opts.body = req.body
    vim.notify("http-runner: using raw body: " .. req.body, vim.log.levels.DEBUG)
    if req.headers then
      opts.headers = req.headers
    end

  elseif req.params then
    local ct = header_value(req.headers, "Content-Type")
    if ct and ct:lower():find("application/json") then
      opts.body = vim.json.encode(req.params)
      if not req.headers then req.headers = {} end
      req.headers["Content-Type"] = "application/json"
      opts.headers = req.headers
      vim.notify("http-runner: params as JSON: " .. opts.body, vim.log.levels.DEBUG)
    else
      local parts = {}
      for k, v in pairs(req.params) do
        table.insert(parts, urlencode(k) .. "=" .. urlencode(v))
      end
      opts.body = table.concat(parts, "&")
      if not req.headers then req.headers = {} end
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      opts.headers = req.headers
      vim.notify("http-runner: params as urlencoded: " .. opts.body, vim.log.levels.DEBUG)
    end

  elseif req.headers then
    opts.headers = req.headers
  end

  vim.notify(
    "http-runner: calling curl." .. req.method:lower() .. "('" .. req.url .. "', " .. vim.inspect(opts) .. ")",
    vim.log.levels.DEBUG
  )

  local ok2, res = pcall(fn, req.url, opts)
  if not ok2 then
    vim.notify(
      "http-runner: request failed with error: " .. tostring(res),
      vim.log.levels.ERROR
    )
    return
  end

  vim.notify(
    "http-runner: response status=" .. (res.status or "nil")
      .. " body_len=" .. ((res.body or ""):len())
      .. " headers_count=" .. (#(res.headers or {})),
    vim.log.levels.INFO
  )
  return res
end

local function show_response(res)
  if not res then
    vim.notify("http-runner: no response to display", vim.log.levels.WARN)
    return
  end

  vim.notify("http-runner: opening response in right vsplit", vim.log.levels.DEBUG)
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
    local body_lines = vim.split(res.body, "\n", { plain = true })
    vim.list_extend(content, body_lines)
    vim.notify(
      "http-runner: wrote " .. #body_lines .. " body lines to response buffer",
      vim.log.levels.DEBUG
    )
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modified = false
  vim.bo[buf].filetype = "http-response"

  vim.notify("http-runner: response displayed", vim.log.levels.DEBUG)
end

map("n", "<leader>rq", function()
  vim.notify("http-runner: <leader>rq triggered", vim.log.levels.DEBUG)

  if not is_http_buffer() then
    vim.notify(
      "http-runner: buffer is not a .http file (bufname="
        .. vim.api.nvim_buf_get_name(0) .. ")",
      vim.log.levels.WARN
    )
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.notify("http-runner: buffer has " .. #lines .. " lines", vim.log.levels.DEBUG)

  if #lines == 0 then
    vim.notify("http-runner: buffer is empty", vim.log.levels.WARN)
    return
  end

  local raw_cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = raw_cursor[1]
  vim.notify(
    "http-runner: cursor (0-idx) row=" .. cursor_row .. " col=" .. raw_cursor[2],
    vim.log.levels.DEBUG
  )

  if cursor_row < 0 or cursor_row >= #lines then
    vim.notify(
      "http-runner: cursor row " .. cursor_row .. " out of range [0, " .. (#lines - 1) .. "]",
      vim.log.levels.WARN
    )
    return
  end

  local current_line = get_line(buf, cursor_row)
  vim.notify(
    "http-runner: current line (0-idx row " .. cursor_row .. ") = '" .. (current_line or "nil") .. "'",
    vim.log.levels.DEBUG
  )

  if current_line == "" then
    vim.notify("http-runner: cursor is on an empty line", vim.log.levels.WARN)
    return
  end
  if current_line and current_line:match("^###") then
    vim.notify("http-runner: cursor is on a ### separator line", vim.log.levels.WARN)
    return
  end

  local start_row, end_row = find_block(buf, lines, cursor_row)
  if not start_row then
    vim.notify("http-runner: could not find request block", vim.log.levels.WARN)
    return
  end

  local req = parse_request(buf, lines, start_row, end_row)

  if not req.url then
    vim.notify(
      "http-runner: no URL found — rows " .. start_row .. "-" .. end_row
        .. " do not contain METHOD URL",
      vim.log.levels.WARN
    )
    return
  end

  vim.notify("http-runner: executing request", vim.log.levels.INFO)
  local res = execute(req)
  show_response(res)
end, { desc = "Execute HTTP request under cursor" })