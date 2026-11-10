local M = {}
local parser = require "moonshine.csv_render.parser"
local render = require "moonshine.csv_render.render"
local map = require "mappings.map"
local ns = vim.api.nvim_create_namespace "moonshine.csv-render"
local sessions, previews, attached = {}, {}, {}
local options =
  { fit_columns = 10, min_column_width = 4, max_column_width = 40 }
local window_options = {
  wrap = false,
  linebreak = false,
  breakindent = false,
  foldenable = false,
  spell = false,
  statuscolumn = "",
  list = false,
  number = false,
  relativenumber = false,
  signcolumn = "no",
  foldcolumn = "0",
}

local function window(session, win)
  if not session.windows[win] then
    local saved = {}
    for key in pairs(window_options) do
      saved[key] = vim.api.nvim_get_option_value(key, { win = win })
    end
    session.windows[win] = saved
  end
  for key, value in pairs(window_options) do
    vim.api.nvim_set_option_value(key, value, { win = win })
  end
end

local function source_position(session, win)
  local doc = session.doc
  if not doc or #doc.records == 0 then
    return session.anchor
  end
  local cursor = vim.api.nvim_win_get_cursor(win)
  local record = doc.records[render.record_at(doc, cursor[1])]
  local line = vim.api.nvim_buf_get_lines(
    session.preview,
    cursor[1] - 1,
    cursor[1],
    false
  )[1] or ""
  local display_col = vim.fn.strdisplaywidth(line:sub(1, cursor[2]))
  local col, offset = 1, 0
  for index, width in ipairs(doc.widths) do
    col = index
    offset = offset + width + 3
    if display_col < offset then
      break
    end
  end
  return record.positions[col] or { record.first, 0 }
end

local function preview_position(doc, position)
  for index, record in ipairs(doc.records) do
    if record.last >= position[1] then
      local column = 1
      for col, pos in ipairs(record.positions) do
        if
          pos[1] < position[1]
          or (pos[1] == position[1] and pos[2] <= position[2])
        then
          column = col
        end
      end
      local text = doc.lines[doc.starts[index]]
      local target = 2
      for col = 1, column - 1 do
        target = target + doc.widths[col] + 3
      end
      local byte, display = 0, 0
      for _, char in ipairs(vim.fn.split(text, "\\zs")) do
        if display >= target then
          break
        end
        byte = byte + #char
        display = display + vim.fn.strdisplaywidth(char)
      end
      return { doc.starts[index], byte }
    end
  end
  return { 1, 0 }
end

local function write_preview(session, lines)
  vim.bo[session.preview].readonly = false
  vim.bo[session.preview].modifiable = true
  vim.api.nvim_buf_set_lines(session.preview, 0, -1, false, lines)
  vim.bo[session.preview].modified = false
  vim.bo[session.preview].modifiable = false
  vim.bo[session.preview].readonly = true
end

local function clear_headers(session)
  for _, header in pairs(session.headers) do
    if vim.api.nvim_buf_is_valid(session.preview) then
      vim.api.nvim_buf_clear_namespace(session.preview, header.ns, 0, -1)
    end
  end
  session.headers = {}
end

local function pin_headers(session)
  local doc = session.doc
  if not doc or not doc.headers or #doc.headers == 0 then
    return
  end
  local last = doc.headers[#doc.headers] + 1 -- Include the header separator.
  for _, win in ipairs(vim.fn.win_findbuf(session.preview)) do
    vim.api.nvim_win_call(win, function()
      local view = vim.fn.winsaveview()
      local height = vim.api.nvim_win_get_height(win)
      local limit = math.min(last, math.max(1, height - 2))
      local count = math.min(view.topline - 1, limit)
      -- At the bottom edge Neovim otherwise discards topfill to make room for
      -- the cursor. Reserve the header's screen rows before adding it. The
      -- prefix grows while the original header is only partly scrolled away.
      while count > 0 do
        local body = height - count
        local margin =
          math.min(vim.wo[win].scrolloff, math.floor((body - 1) / 2))
        local top = math.max(view.topline, view.lnum - body + margin + 1)
        view.topline = top
        local next_count = math.min(top - 1, limit)
        if next_count == count then
          break
        end
        count = next_count
      end
      local header = session.headers[win]
      if not header then
        local namespace =
          vim.api.nvim_create_namespace("moonshine.csv-render.header." .. win)
        -- Each split can scroll independently while displaying the same buffer.
        vim.api.nvim__ns_set(namespace, { wins = { win } })
        header = { ns = namespace }
        session.headers[win] = header
      end
      if header.row ~= view.topline or header.count ~= count then
        vim.api.nvim_buf_clear_namespace(session.preview, header.ns, 0, -1)
        if count > 0 then
          local lines = {}
          for row = 1, count do
            lines[#lines + 1] = {
              {
                doc.lines[row],
                row > 1 and row < last and "Title" or "Delimiter",
              },
            }
          end
          vim.api.nvim_buf_set_extmark(
            session.preview,
            header.ns,
            view.topline - 1,
            0,
            {
              virt_lines = lines,
              virt_lines_above = true,
              virt_lines_overflow = "scroll",
            }
          )
        end
        header.row, header.count = view.topline, count
      end
      if view.topfill ~= header.count or vim.fn.line "w0" ~= view.topline then
        view.topfill = header.count
        vim.fn.winrestview(view)
      end
    end)
  end
end

local refresh
refresh = function(session)
  if
    sessions[session.source] ~= session
    or not vim.api.nvim_buf_is_valid(session.preview)
  then
    return
  end
  local wins = vim.fn.win_findbuf(session.preview)
  if #wins == 0 then
    return
  end
  local width = vim.api.nvim_win_get_width(wins[1])
  for _, win in ipairs(wins) do
    window(session, win)
    width = math.min(width, vim.api.nvim_win_get_width(win))
  end
  local tick = vim.api.nvim_buf_get_changedtick(session.source)
  if session.doc and session.tick == tick and session.width == width then
    return
  end
  session.generation = session.generation + 1
  local generation = session.generation
  local anchors = {}
  for _, win in ipairs(wins) do
    anchors[win] = source_position(session, win)
  end
  local function checkpoint(index)
    if index % 25 == 0 then
      coroutine.yield()
    end
  end
  local task = coroutine.create(function()
    local records = session.tick == tick and session.records or nil
    if not records then
      local lines = vim.api.nvim_buf_get_lines(session.source, 0, -1, false)
      local delimiter = parser.delimiter(lines, vim.bo[session.source].filetype)
      records = parser.parse(lines, delimiter, checkpoint)
    end
    local doc = render.build(records, width, options, checkpoint)
    -- Publish only complete output; cancelled jobs never replace the preview.
    clear_headers(session)
    session.records, session.doc, session.tick, session.width =
      records, doc, tick, width
    write_preview(session, doc.lines)
    vim.api.nvim_buf_clear_namespace(session.preview, ns, 0, -1)
    for _, row in ipairs(doc.headers or {}) do
      vim.api.nvim_buf_set_extmark(
        session.preview,
        ns,
        row - 1,
        0,
        { line_hl_group = "Title" }
      )
    end
    for win, position in pairs(anchors) do
      if
        vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_win_get_buf(win) == session.preview
      then
        vim.api.nvim_win_set_cursor(win, preview_position(doc, position))
      end
    end
    pin_headers(session)
  end)
  local function step()
    if
      sessions[session.source] ~= session or generation ~= session.generation
    then
      return
    end
    if
      not vim.api.nvim_buf_is_valid(session.source)
      or not vim.api.nvim_buf_is_valid(session.preview)
    then
      return
    end
    if vim.api.nvim_buf_get_changedtick(session.source) ~= tick then
      refresh(session)
      return
    end
    local ok, err = coroutine.resume(task)
    if not ok then
      session.doc, session.records, session.tick = nil, nil, nil
      write_preview(session, {
        "CSV preview: " .. tostring(err),
        "",
        "Press <A-i> or q to return to the source.",
      })
      vim.notify("CSV preview: " .. tostring(err), vim.log.levels.ERROR)
    elseif coroutine.status(task) ~= "dead" then
      vim.schedule(step)
    end
  end
  vim.schedule(step)
end

local function queue_refresh(session)
  session.generation = session.generation + 1
  local generation = session.generation
  vim.defer_fn(function()
    if
      sessions[session.source] == session and session.generation == generation
    then
      refresh(session)
    end
  end, 100)
end

function M.close(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local source = previews[buf] or buf
  local session = sessions[source]
  if not session then
    return
  end
  sessions[source], previews[session.preview] = nil, nil
  session.generation = session.generation + 1
  clear_headers(session)
  for _, win in ipairs(vim.fn.win_findbuf(session.preview)) do
    local position = source_position(session, win)
    if
      vim.api.nvim_buf_is_valid(source) and vim.api.nvim_buf_is_loaded(source)
    then
      vim.api.nvim_win_set_buf(win, source)
      local row = math.min(position[1], vim.api.nvim_buf_line_count(source))
      vim.api.nvim_win_set_cursor(win, { row, position[2] })
    end
    for key, value in pairs(session.windows[win] or {}) do
      vim.api.nvim_set_option_value(key, value, { win = win })
    end
  end
  vim.api.nvim_del_augroup_by_id(session.group)
  if vim.api.nvim_buf_is_valid(session.preview) then
    vim.api.nvim_buf_delete(session.preview, { force = true })
  end
end

function M.toggle()
  local source = vim.api.nvim_get_current_buf()
  if previews[source] then
    M.close(source)
    return
  end
  if sessions[source] then
    M.close(source)
    return
  end
  local win = vim.api.nvim_get_current_win()
  local preview = vim.api.nvim_create_buf(false, true)
  local session = {
    source = source,
    preview = preview,
    anchor = vim.api.nvim_win_get_cursor(win),
    windows = {},
    headers = {},
    generation = 0,
    group = vim.api.nvim_create_augroup(
      "MoonshineCsvRender" .. preview,
      { clear = true }
    ),
  }
  sessions[source], previews[preview] = session, source
  vim.api.nvim_buf_set_name(
    preview,
    "csv-preview://"
      .. source
      .. "/"
      .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(source), ":t")
  )
  vim.bo[preview].bufhidden = "hide"
  vim.bo[preview].swapfile = false
  vim.bo[preview].undolevels = -1
  vim.bo[preview].readonly = true
  write_preview(session, { "Rendering CSV preview…" })
  -- The source may have unsaved edits while 'hidden' is disabled. Keep it
  -- loaded for this buffer switch without changing the user's global option.
  local bufhidden = vim.bo[source].bufhidden
  vim.bo[source].bufhidden = "hide"
  -- Snapshot the source window before entering a preview FileType/BufWinEnter.
  window(session, win)
  vim.api.nvim_win_set_buf(win, preview)
  vim.bo[source].bufhidden = bufhidden
  vim.bo[preview].filetype = "csv-preview"
  window(session, win)
  for _, key in ipairs { "<A-i>", "q", "<Esc>" } do
    map("n", key, function()
      M.close(preview)
    end, { buffer = preview, silent = true, desc = "Close CSV preview" })
  end
  vim.api.nvim_create_autocmd({ "WinResized", "VimResized" }, {
    group = session.group,
    callback = function()
      queue_refresh(session)
    end,
  })
  vim.api.nvim_create_autocmd({ "WinScrolled", "CursorMoved" }, {
    group = session.group,
    callback = function()
      pin_headers(session)
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = session.group,
    buffer = preview,
    callback = function()
      window(session, vim.api.nvim_get_current_win())
      queue_refresh(session)
    end,
  })
  vim.api.nvim_create_autocmd("BufWinLeave", {
    group = session.group,
    buffer = preview,
    callback = function()
      local leaving = vim.api.nvim_get_current_win()
      for key, value in pairs(session.windows[leaving] or {}) do
        vim.api.nvim_set_option_value(key, value, { win = leaving })
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = session.group,
    buffer = preview,
    callback = function()
      -- Wiping a preview also releases all source and resize listeners.
      sessions[source], previews[preview] = nil, nil
      clear_headers(session)
      vim.api.nvim_del_augroup_by_id(session.group)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = session.group,
    buffer = source,
    callback = function()
      vim.schedule(function()
        M.close(source)
      end)
    end,
  })
  -- One listener per source, independent of preview lifetime. Reopening a
  -- large file must not retain old documents through attached callbacks.
  if not attached[source] then
    attached[source] = vim.api.nvim_buf_attach(source, false, {
      on_lines = function()
        if sessions[source] then
          queue_refresh(sessions[source])
        end
      end,
      on_reload = function()
        if sessions[source] then
          queue_refresh(sessions[source])
        end
      end,
      on_detach = function()
        attached[source] = nil
      end,
    })
  end
  refresh(session)
end

function M.setup(opts)
  options = vim.tbl_extend("force", options, opts or {})
end

return M
