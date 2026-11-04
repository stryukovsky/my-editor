local map = require "mappings.map"

local active_curls = {}

local function cancel_requests()
  local count = 0
  for pid, request in pairs(active_curls) do
    local ok = vim.uv.kill(pid, "sigterm")
    if ok then
      request.cancelled = true
      count = count + 1
    end
  end
  return count
end

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = vim.api.nvim_create_augroup("HttpRunnerCurls", { clear = true }),
  callback = cancel_requests,
})

-- Responses belong to the source buffer and survive switching buffers.

local function run(debug_mode)
  local source_buf = vim.api.nvim_get_current_buf()
  local source_win = vim.api.nvim_get_current_win()
  local function log(msg, level)
    if
      not debug_mode
      and (level == vim.log.levels.DEBUG or level == vim.log.levels.INFO)
    then
      return
    end
    vim.notify("http-runner: " .. msg, level or vim.log.levels.INFO)
  end

  local function is_http_buffer()
    local name = vim.api.nvim_buf_get_name(0)
    local ok = name:match "%.http$" ~= nil
    log(
      "buffer name='" .. name .. "', is_http=" .. tostring(ok),
      vim.log.levels.DEBUG
    )
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
    log(
      "find_block total_lines=" .. n .. " cursor_row(0-idx)=" .. cursor_row,
      vim.log.levels.DEBUG
    )

    local block_start = 0
    local i = cursor_row - 1
    while i >= 0 do
      local line = get_line(buf, i)
      log(
        "backward scan row=" .. i .. " line='" .. (line or "nil") .. "'",
        vim.log.levels.DEBUG
      )
      if line and line:match "^###" then
        block_start = i + 1
        log(
          "found ### at row " .. i .. ", block_start=" .. block_start,
          vim.log.levels.DEBUG
        )
        break
      elseif line == "" then
        local blanks = count_consecutive_blanks(lines, i, -1)
        log(
          "blanks backward from row " .. i .. " = " .. blanks,
          vim.log.levels.DEBUG
        )
        if blanks >= 2 then
          block_start = i + 1
          log(
            "2+ blanks at row " .. i .. ", block_start=" .. block_start,
            vim.log.levels.DEBUG
          )
          break
        end
      end
      i = i - 1
    end

    local block_end = n - 1
    i = cursor_row + 1
    while i < n do
      local line = get_line(buf, i)
      log(
        "forward scan row=" .. i .. " line='" .. (line or "nil") .. "'",
        vim.log.levels.DEBUG
      )
      if line and line:match "^###" then
        block_end = i - 1
        log(
          "found ### at row " .. i .. ", block_end=" .. block_end,
          vim.log.levels.DEBUG
        )
        break
      elseif line == "" then
        local blanks = count_consecutive_blanks(lines, i, 1)
        log(
          "blanks forward from row " .. i .. " = " .. blanks,
          vim.log.levels.DEBUG
        )
        if blanks >= 2 then
          block_end = i - 1
          log(
            "2+ blanks at row " .. i .. ", block_end=" .. block_end,
            vim.log.levels.DEBUG
          )
          break
        end
      end
      i = i + 1
    end

    log(
      "block range (0-idx) " .. block_start .. " -> " .. block_end,
      vim.log.levels.DEBUG
    )

    if block_start > block_end then
      log(
        "empty block (start " .. block_start .. " > end " .. block_end .. ")",
        vim.log.levels.WARN
      )
      return nil
    end

    return block_start, block_end
  end

  local function urlencode(s)
    return (
      tostring(s):gsub("([^%w%.%-_~])", function(c)
        return string.format("%%%02X", c:byte())
      end)
    )
  end

  local function header_value(headers, name)
    if not headers then
      return nil
    end
    for k, v in pairs(headers) do
      if k:lower() == name:lower() then
        return v
      end
    end
    return nil
  end

  local function parse_request(buf, lines, start_row, end_row)
    local method, url, headers, params, body_lines, name
    local in_body = false
    local body_is_json = false

    log(
      "parsing rows (0-idx) " .. start_row .. "-" .. end_row,
      vim.log.levels.DEBUG
    )

    for row = start_row, end_row do
      local line = get_line(buf, row)
      log(
        " parse row "
          .. row
          .. " in_body="
          .. tostring(in_body)
          .. " '"
          .. (line or "nil")
          .. "'",
        vim.log.levels.DEBUG
      )

      if not line then
        log(" -> nil line (skip)", vim.log.levels.DEBUG)
      elseif not method and line:match "^%s*#%s*@name%s+" then
        name = line:match "^%s*#%s*@name%s+([%w_%-]+)"
      elseif not method and line:match "^%s*@[%w_%-]+%s*=" then
        -- File variables are collected separately.
      elseif line:match "^%s*#" then
        log(" -> comment (skip)", vim.log.levels.DEBUG)
      elseif not method then
        method, url = line:match "^(%S+)%s+(%S+)"
        if method then
          log(
            " -> method='" .. method .. "' url='" .. (url or "nil") .. "'",
            vim.log.levels.DEBUG
          )
        else
          log(" -> not a METHOD URL line (no match)", vim.log.levels.DEBUG)
        end
      elseif in_body then
        if not body_is_json then
          local trimmed = line:match "^%s*(.-)%s*$"
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
          local pkey, pval = line:match "^([%w%.%-_]+)=(.+)$"
          if pkey then
            if not params then
              params = {}
            end
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
        local key, value = line:match "^([%w%-]+):%s*(.+)"
        if key then
          if not headers then
            headers = {}
          end
          headers[key] = value
          log(" -> header " .. key .. ": " .. value, vim.log.levels.DEBUG)
        else
          local pkey, pval = line:match "^([%w%.%-_]+)=(.+)$"
          if pkey then
            if not params then
              params = {}
            end
            params[pkey] = pval
            log(" -> param " .. pkey .. "=" .. pval, vim.log.levels.DEBUG)
          else
            log(
              " -> unrecognized line (not header/param/blank/method/comment)",
              vim.log.levels.DEBUG
            )
          end
        end
      end
    end

    local body = body_lines
        and #body_lines > 0
        and table.concat(body_lines, "\n")
      or nil
    log(
      "parsed method="
        .. (method or "GET (default)")
        .. " url="
        .. (url or "nil")
        .. " headers="
        .. vim.inspect(headers)
        .. " params="
        .. vim.inspect(params)
        .. " body="
        .. (body and #body > 0 and #body .. " chars" or "nil")
        .. " body_is_json="
        .. tostring(body_is_json),
      vim.log.levels.DEBUG
    )

    return {
      name = name,
      method = method and method:upper() or "GET",
      url = url,
      headers = headers,
      params = params,
      body = body,
    }
  end

  local function execute(req, on_complete)
    log(
      "executing " .. req.method .. " " .. (req.url or "nil"),
      vim.log.levels.INFO
    )

    local ok, curl = pcall(require, "plenary.curl")
    if not ok then
      log(
        "failed to require plenary.curl: " .. tostring(curl),
        vim.log.levels.ERROR
      )
      return
    end
    log("plenary.curl loaded", vim.log.levels.DEBUG)

    local fn = curl[req.method:lower()]
    if not fn then
      log(
        "unsupported method '"
          .. req.method
          .. "', available: "
          .. vim.inspect(vim.tbl_keys(curl)),
        vim.log.levels.ERROR
      )
      return
    end

    local opts = {}

    if req.method == "GET" and req.params then
      opts.query = req.params
      log(
        "using params as query: " .. vim.inspect(req.params),
        vim.log.levels.DEBUG
      )
      if req.headers then
        opts.headers = req.headers
      end
    elseif req.body then
      opts.body = req.body
      log("using raw body: " .. req.body, vim.log.levels.DEBUG)
      if not req.headers then
        req.headers = {}
      end
      if
        not header_value(req.headers, "Content-Type")
        and req.body:match "^%s*{"
      then
        req.headers["Content-Type"] = "application/json"
        log(
          "auto-set Content-Type: application/json for JSON body",
          vim.log.levels.DEBUG
        )
      end
      opts.headers = req.headers
    elseif req.params then
      local ct = header_value(req.headers, "Content-Type")
      if ct and ct:lower():find "application/json" then
        opts.body = vim.json.encode(req.params)
        if not req.headers then
          req.headers = {}
        end
        req.headers["Content-Type"] = "application/json"
        opts.headers = req.headers
        log("params as JSON: " .. opts.body, vim.log.levels.DEBUG)
      else
        local parts = {}
        for k, v in pairs(req.params) do
          table.insert(parts, urlencode(k) .. "=" .. urlencode(v))
        end
        opts.body = table.concat(parts, "&")
        if not req.headers then
          req.headers = {}
        end
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        opts.headers = req.headers
        log("params as urlencoded: " .. opts.body, vim.log.levels.DEBUG)
      end
    elseif req.headers then
      opts.headers = req.headers
    end

    log(
      "calling curl."
        .. req.method:lower()
        .. "('"
        .. req.url
        .. "', "
        .. vim.inspect(opts)
        .. ")",
      vim.log.levels.DEBUG
    )

    local request = {}
    -- A curl killed before startup may never create its headers file. Plenary
    -- still parses it when a signal reports exit code zero, so create it first.
    local headers_path = vim.fn.tempname()
    vim.fn.writefile({}, headers_path)
    opts.dump = { "-D", headers_path }
    local function finish(res)
      vim.uv.fs_unlink(headers_path)
      if request.pid then
        active_curls[request.pid] = nil
      end
      vim.schedule(function()
        if not request.cancelled then
          on_complete(res)
        end
      end)
    end
    -- A callback makes Plenary start an asynchronous job without its sync timeout.
    opts.callback = finish
    opts.on_error = function(err)
      finish {
        error = true,
        body = req.method
          .. " "
          .. req.url
          .. "\n\n"
          .. (err.message or "Request failed")
          .. (err.exit and "\nCurl exit code: " .. err.exit or ""),
      }
    end
    local started, job = pcall(fn, req.url, opts)
    if not started then
      opts.on_error { message = tostring(job) }
    elseif job and job.pid then
      request.pid = job.pid
      active_curls[job.pid] = request
    end
  end

  local function show_response(res)
    if not res then
      log("no response to display", vim.log.levels.WARN)
      return
    end

    local buf = vim.api.nvim_create_buf(true, false)

    local content = {}
    table.insert(
      content,
      res.error and "Request failed" or "Status: " .. (res.status or "?")
    )
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
      log(
        "wrote " .. #body_lines .. " body lines to response buffer",
        vim.log.levels.DEBUG
      )
    end

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.bo[buf].modified = false
    vim.bo[buf].filetype = "http-response"

    if
      vim.api.nvim_win_is_valid(source_win)
      and vim.api.nvim_win_get_buf(source_win) == source_buf
    then
      vim.api.nvim_win_set_buf(source_win, buf)
    else
      vim.notify("http-runner: response available in buffer " .. buf)
    end

    log("response displayed", vim.log.levels.DEBUG)
  end

  -- ---- main handler ----
  log(
    "<leader>rq triggered (debug=" .. tostring(debug_mode) .. ")",
    vim.log.levels.DEBUG
  )

  if not is_http_buffer() then
    log(
      "buffer is not a .http file (bufname="
        .. vim.api.nvim_buf_get_name(0)
        .. ")",
      vim.log.levels.WARN
    )
    return
  end

  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  log("buffer has " .. #lines .. " lines", vim.log.levels.DEBUG)

  if #lines == 0 then
    log("buffer is empty", vim.log.levels.WARN)
    return
  end

  local cursor_row = vim.fn.line "." - 1
  log("cursor (0-idx) row=" .. cursor_row, vim.log.levels.DEBUG)

  if cursor_row < 0 or cursor_row >= #lines then
    log(
      "cursor row " .. cursor_row .. " out of range [0, " .. (#lines - 1) .. "]",
      vim.log.levels.WARN
    )
    return
  end

  local current_line = get_line(buf, cursor_row)
  log(
    "current line (0-idx row "
      .. cursor_row
      .. ") = '"
      .. (current_line or "nil")
      .. "'",
    vim.log.levels.DEBUG
  )

  if current_line == "" then
    log("cursor is on an empty line", vim.log.levels.WARN)
    return
  end
  if current_line and current_line:match "^###" then
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
    log(
      "no URL found — rows "
        .. start_row
        .. "-"
        .. end_row
        .. " do not contain METHOD URL",
      vim.log.levels.WARN
    )
    return
  end

  local variables = {}
  for _, line in ipairs(lines) do
    local key, value = line:match "^%s*@([%w_%-]+)%s*=%s*(.-)%s*$"
    if key then
      variables[key] = value
    end
  end

  local saved = vim.b[buf].http_runner_responses or {}
  local resolving = {}
  local interpolate
  local function resolve(expression)
    expression = vim.trim(expression)
    if variables[expression] ~= nil then
      if resolving[expression] then
        error("circular variable: " .. expression, 0)
      end
      resolving[expression] = true
      local value = interpolate(variables[expression])
      resolving[expression] = nil
      return value
    end

    local name, path = expression:match "^([%w_%-]+)%.response%.body%.%$(.*)$"
    if not name then
      error("unknown variable: " .. expression, 0)
    end
    local response = saved[name]
    if not response then
      error("run named request '" .. name .. "' first", 0)
    end
    local ok, value = pcall(vim.json.decode, response.body or "")
    if not ok then
      error("response '" .. name .. "' is not JSON", 0)
    end
    while path ~= "" do
      local key, rest = path:match "^%.([%w_%-]+)(.*)$"
      local index
      if not key then
        index, rest = path:match "^%[(%d+)%](.*)$"
      end
      if not key and not index then
        error("unsupported response path: " .. expression, 0)
      end
      if type(value) ~= "table" then
        error("missing response value: " .. expression, 0)
      end
      value = value[key or (tonumber(index) + 1)]
      path = rest
    end
    if value == nil or value == vim.NIL then
      error("missing response value: " .. expression, 0)
    end
    return type(value) == "table" and vim.json.encode(value) or tostring(value)
  end
  interpolate = function(value)
    return (value:gsub("{{%s*(.-)%s*}}", resolve))
  end

  local resolved, err = pcall(function()
    req.url = interpolate(req.url)
    if req.body then
      req.body = interpolate(req.body)
    end
    for _, values in ipairs { req.headers or {}, req.params or {} } do
      for key, value in pairs(values) do
        values[key] = interpolate(value)
      end
    end
  end)
  if not resolved then
    log(err, vim.log.levels.ERROR)
    return
  end

  log("executing request", vim.log.levels.INFO)
  execute(req, function(res)
    if
      res
      and not res.error
      and req.name
      and vim.api.nvim_buf_is_valid(buf)
    then
      local responses = vim.b[buf].http_runner_responses or {}
      responses[req.name] = { body = res.body }
      vim.b[buf].http_runner_responses = responses
    end
    show_response(res)
  end)
end

map("n", "<leader>rq", function()
  run(--[[ debug_mode = ]] false)
end, { desc = "Execute HTTP request under cursor" })

map("n", "<leader>rQ", function()
  local count = cancel_requests()
  vim.notify("http-runner: cancelled " .. count .. " active curl request(s)")
end, { desc = "Cancel all HTTP requests in this Neovim instance" })
