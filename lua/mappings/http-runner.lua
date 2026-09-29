local map = require "mappings.map"

local function run(debug_mode)
  local function log(msg, level)
    if not debug_mode and (level == vim.log.levels.DEBUG or level == vim.log.levels.INFO) then
      return
    end
    vim.notify("http-runner: " .. msg, level or vim.log.levels.INFO)
  end

  local function is_http_buffer()
    local name = vim.api.nvim_buf_get_name(0)
    local ok = name:match("%.http$") ~= nil
    log("buffer name='" .. name .. "', is_http=" .. tostring(ok), vim.log.levels.DEBUG)
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
    log("find_block total_lines=" .. n .. " cursor_row(0-idx)=" .. cursor_row, vim.log.levels.DEBUG)

    local block_start = 0
    local i = cursor_row - 1
    while i >= 0 do
      local line = get_line(buf, i)
      log("backward scan row=" .. i .. " line='" .. (line or "nil") .. "'", vim.log.levels.DEBUG)
      if line and line:match("^###") then
        block_start = i + 1
        log("found ### at row " .. i .. ", block_start=" .. block_start, vim.log.levels.DEBUG)
        break
      elseif line == "" then
        local blanks = count_consecutive_blanks(lines, i, -1)
        log("blanks backward from row " .. i .. " = " .. blanks, vim.log.levels.DEBUG)
        if blanks >= 2 then
          block_start = i + 1
          log("2+ blanks at row " .. i .. ", block_start=" .. block_start, vim.log.levels.DEBUG)
          break
        end
      end
      i = i - 1
    end

    local block_end = n - 1
    i = cursor_row + 1
    while i < n do
      local line = get_line(buf, i)
      log("forward scan row=" .. i .. " line='" .. (line or "nil") .. "'", vim.log.levels.DEBUG)
      if line and line:match("^###") then
        block_end = i - 1
        log("found ### at row " .. i .. ", block_end=" .. block_end, vim.log.levels.DEBUG)
        break
      elseif line == "" then
        local blanks = count_consecutive_blanks(lines, i, 1)
        log("blanks forward from row " .. i .. " = " .. blanks, vim.log.levels.DEBUG)
        if blanks >= 2 then
          block_end = i - 1
          log("2+ blanks at row " .. i .. ", block_end=" .. block_end, vim.log.levels.DEBUG)
          break
        end
      end
      i = i + 1
    end

    log("block range (0-idx) " .. block_start .. " -> " .. block_end, vim.log.levels.DEBUG)

    if block_start > block_end then
      log("empty block (start " .. block_start .. " > end " .. block_end .. ")", vim.log.levels.WARN)
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

    log("parsing rows (0-idx) " .. start_row .. "-" .. end_row, vim.log.levels.DEBUG)

    for row = start_row, end_row do
      local line = get_line(buf, row)
      log(" parse row " .. row .. " in_body=" .. tostring(in_body) .. " '" .. (line or "nil") .. "'", vim.log.levels.DEBUG)

      if not line then
        log(" -> nil line (skip)", vim.log.levels.DEBUG)
      elseif line:match("^#") then
        log(" -> comment (skip)", vim.log.levels.DEBUG)
      elseif not method then
        method, url = line:match("^(%S+)%s+(%S+)")
        if method then
          log(" -> method='" .. method .. "' url='" .. (url or "nil") .. "'", vim.log.levels.DEBUG)
        else
          log(" -> not a METHOD URL line (no match)", vim.log.levels.DEBUG)
        end
      elseif in_body then
        if not body_is_json then
          local trimmed = line:match("^%s*(.-)%s*$")
          if trimmed and trimmed ~= "" then
            if trimmed:sub(1, 1) == "{" then
              body_is_json = true
              log(" -> body is JSON", vim.log.levels.DEBUG)
            end
          end
        end
        if body_is_json then
          table.insert(body_lines, line)
          log(" -> body line", vim.log.levels.DEBUG)
        else
          local pkey, pval = line:match("^([%w%.%-_]+)=(.+)$")
          if pkey then
            if not params then params = {} end
            params[pkey] = pval
            log(" -> body param " .. pkey .. "=" .. pval, vim.log.levels.DEBUG)
          else
            table.insert(body_lines, line)
            log(" -> body line (non-param)", vim.log.levels.DEBUG)
          end
        end
      elseif line == "" then
        in_body = true
        body_lines = {}
        log(" -> blank line, switching to body", vim.log.levels.DEBUG)
      else
        local key, value = line:match("^([%w%-]+):%s*(.+)")
        if key then
          if not headers then headers = {} end
          headers[key] = value
          log(" -> header " .. key .. ": " .. value, vim.log.levels.DEBUG)
        else
          local pkey, pval = line:match("^([%w%.%-_]+)=(.+)$")
          if pkey then
            if not params then params = {} end
            params[pkey] = pval
            log(" -> param " .. pkey .. "=" .. pval, vim.log.levels.DEBUG)
          else
            log(" -> unrecognized line (not header/param/blank/method/comment)", vim.log.levels.DEBUG)
          end
        end
      end
    end

    local body = body_lines and #body_lines > 0 and table.concat(body_lines, "\n") or nil
    log("parsed method=" .. (method or "GET (default)")
      .. " url=" .. (url or "nil")
      .. " headers=" .. vim.inspect(headers)
      .. " params=" .. vim.inspect(params)
      .. " body=" .. (body and #body > 0 and #body .. " chars" or "nil")
      .. " body_is_json=" .. tostring(body_is_json), vim.log.levels.DEBUG)

    return {
      method = method and method:upper() or "GET",
      url = url,
      headers = headers,
      params = params,
      body = body,
    }
  end

  local function execute(req)
    log("executing " .. req.method .. " " .. (req.url or "nil"), vim.log.levels.INFO)

    local ok, curl = pcall(require, "plenary.curl")
    if not ok then
      log("failed to require plenary.curl: " .. tostring(curl), vim.log.levels.ERROR)
      return
    end
    log("plenary.curl loaded", vim.log.levels.DEBUG)

    local fn = curl[req.method:lower()]
    if not fn then
      log("unsupported method '" .. req.method .. "', available: " .. vim.inspect(vim.tbl_keys(curl)), vim.log.levels.ERROR)
      return
    end

    local opts = {}

    if req.method == "GET" and req.params then
      opts.query = req.params
      log("using params as query: " .. vim.inspect(req.params), vim.log.levels.DEBUG)
      if req.headers then
        opts.headers = req.headers
      end

    elseif req.body then
      opts.body = req.body
      log("using raw body: " .. req.body, vim.log.levels.DEBUG)
      if not req.headers then req.headers = {} end
      if not header_value(req.headers, "Content-Type") and req.body:match("^%s*{") then
        req.headers["Content-Type"] = "application/json"
        log("auto-set Content-Type: application/json for JSON body", vim.log.levels.DEBUG)
      end
      opts.headers = req.headers

    elseif req.params then
      local ct = header_value(req.headers, "Content-Type")
      if ct and ct:lower():find("application/json") then
        opts.body = vim.json.encode(req.params)
        if not req.headers then req.headers = {} end
        req.headers["Content-Type"] = "application/json"
        opts.headers = req.headers
        log("params as JSON: " .. opts.body, vim.log.levels.DEBUG)
      else
        local parts = {}
        for k, v in pairs(req.params) do
          table.insert(parts, urlencode(k) .. "=" .. urlencode(v))
        end
        opts.body = table.concat(parts, "&")
        if not req.headers then req.headers = {} end
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        opts.headers = req.headers
        log("params as urlencoded: " .. opts.body, vim.log.levels.DEBUG)
      end

    elseif req.headers then
      opts.headers = req.headers
    end

    log("calling curl." .. req.method:lower() .. "('" .. req.url .. "', " .. vim.inspect(opts) .. ")", vim.log.levels.DEBUG)

    local ok2, res = pcall(fn, req.url, opts)
    if not ok2 then
      log("request failed with error: " .. tostring(res), vim.log.levels.ERROR)
      return
    end

    log("response status=" .. (res.status or "nil") .. " body_len=" .. ((res.body or ""):len()) .. " headers_count=" .. (#(res.headers or {})), vim.log.levels.INFO)
    return res
  end

  local function show_response(res)
    if not res then
      log("no response to display", vim.log.levels.WARN)
      return
    end

    log("opening response in right vsplit", vim.log.levels.DEBUG)
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
      log("wrote " .. #body_lines .. " body lines to response buffer", vim.log.levels.DEBUG)
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].modified = false
    vim.bo[buf].filetype = "http-response"

    log("response displayed", vim.log.levels.DEBUG)
  end

  -- ---- main handler ----
  log("<leader>rq triggered (debug=" .. tostring(debug_mode) .. ")", vim.log.levels.DEBUG)

  if not is_http_buffer() then
    log("buffer is not a .http file (bufname=" .. vim.api.nvim_buf_get_name(0) .. ")", vim.log.levels.WARN)
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  log("buffer has " .. #lines .. " lines", vim.log.levels.DEBUG)

  if #lines == 0 then
    log("buffer is empty", vim.log.levels.WARN)
    return
  end

  local cursor_row = vim.fn.line(".") - 1
  log("cursor (0-idx) row=" .. cursor_row, vim.log.levels.DEBUG)

  if cursor_row < 0 or cursor_row >= #lines then
    log("cursor row " .. cursor_row .. " out of range [0, " .. (#lines - 1) .. "]", vim.log.levels.WARN)
    return
  end

  local current_line = get_line(buf, cursor_row)
  log("current line (0-idx row " .. cursor_row .. ") = '" .. (current_line or "nil") .. "'", vim.log.levels.DEBUG)

  if current_line == "" then
    log("cursor is on an empty line", vim.log.levels.WARN)
    return
  end
  if current_line and current_line:match("^###") then
    log("cursor is on a ### separator line", vim.log.levels.WARN)
    return
  end

  local start_row, end_row = find_block(buf, lines, cursor_row)
  if not start_row then
    log("could not find request block", vim.log.levels.WARN)
    return
  end

  local req = parse_request(buf, lines, start_row, end_row)

  if not req.url then
    log("no URL found — rows " .. start_row .. "-" .. end_row .. " do not contain METHOD URL", vim.log.levels.WARN)
    return
  end

  log("executing request", vim.log.levels.INFO)
  local res = execute(req)
  show_response(res)
end

map("n", "<leader>rq", function() run(--[[ debug_mode = ]] false) end, { desc = "Execute HTTP request under cursor" })

