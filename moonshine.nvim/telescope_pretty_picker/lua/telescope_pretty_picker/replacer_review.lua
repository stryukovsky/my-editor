local map = require "mappings.map"

local M = {}
local current

local function warn(message)
  require("integrations.notify").send(
    "Ripgrep replacement",
    message,
    vim.log.levels.WARN
  )
end

function M.items()
  local Item = require "trouble.item"
  local items = {}
  for _, match in ipairs(current and current.matches or {}) do
    items[#items + 1] = Item.new {
      id = "telescope_replacer:" .. match.id,
      source = "telescope_replacer",
      filename = match.filename,
      pos = { match.lnum, match.start },
      end_pos = { match.lnum, match.stop },
      replacement = current.replacement,
      item = match,
    }
  end
  return items
end

local function preflight(targets)
  local buffers = {}
  for _, match in ipairs(targets) do
    if not buffers[match.filename] then
      local stat = vim.uv.fs_stat(match.filename)
      if not stat or stat.type ~= "file" then
        error("File unavailable: " .. match.filename, 0)
      end
      local buf = vim.fn.bufadd(match.filename)
      vim.fn.bufload(buf)
      buffers[match.filename] = buf
    end
  end

  local edits = {}
  for _, match in ipairs(targets) do
    local buf = buffers[match.filename]
    if
      not vim.api.nvim_buf_is_loaded(buf)
      or vim.bo[buf].buftype ~= ""
      or vim.bo[buf].readonly
      or not vim.bo[buf].modifiable
    then
      error("Buffer cannot be edited: " .. match.filename, 0)
    end
    local line =
      vim.api.nvim_buf_get_lines(buf, match.lnum - 1, match.lnum, false)[1]
    if
      line ~= match.line
      or match.start < 0
      or match.stop > #line
      or match.start > match.stop
    then
      error(("Match changed: %s:%d"):format(match.filename, match.lnum), 0)
    end
    edits[#edits + 1] = { buf = buf, match = match }
  end
  table.sort(edits, function(a, b)
    if a.buf ~= b.buf then
      return a.buf < b.buf
    end
    if a.match.lnum ~= b.match.lnum then
      return a.match.lnum > b.match.lnum
    end
    return a.match.start > b.match.start
  end)
  return edits
end

local function apply(session, edits, replacement)
  local previous_buf
  for _, edit in ipairs(edits) do
    local buf, match = edit.buf, edit.match
    vim.api.nvim_buf_call(buf, function()
      if previous_buf == buf then
        vim.cmd.undojoin()
      else
        -- Close any prior undo block, including an unrelated unsaved edit.
        vim.cmd "let &l:undolevels = &l:undolevels"
      end
      vim.api.nvim_buf_set_text(
        buf,
        match.lnum - 1,
        match.start,
        match.lnum - 1,
        match.stop,
        { replacement }
      )
    end)
    previous_buf = buf

    local line = match.line:sub(1, match.start)
      .. replacement
      .. match.line:sub(match.stop + 1)
    local delta = #replacement - (match.stop - match.start)
    for i = #session.matches, 1, -1 do
      local other = session.matches[i]
      if other == match then
        table.remove(session.matches, i)
      elseif other.filename == match.filename and other.lnum == match.lnum then
        other.line = line
        if other.start >= match.stop then
          other.start = other.start + delta
          other.stop = other.stop + delta
        end
      end
    end
    vim.bo[buf].buflisted = true
  end
end

local function replace(session, targets, batch)
  if #targets == 0 then
    return
  end
  if
    batch
    and vim.fn.confirm(
        ("Replace all %d remaining occurrences?"):format(#targets),
        "&Yes\n&No",
        2
      )
      ~= 1
  then
    return
  end
  if current ~= session or not session.view:is_open() then
    return
  end

  local ok, failure = pcall(function()
    local edits = preflight(targets)
    if current == session and session.view:is_open() then
      apply(session, edits, session.replacement)
    end
  end)
  if not ok then
    warn(tostring(failure))
  end
  session.view:refresh()
end

function M.open(matches, selected, replacement)
  local session = { matches = matches, replacement = replacement }
  current = session
  require "utils.ui_prevent_mess"()
  local trouble = require "trouble"
  trouble.close "telescope_replacer"
  local view = trouble.open {
    mode = "telescope_replacer",
    focus = true,
    new = true,
    max_items = #matches,
  }
  session.view = view
  view:wait(function()
    if current ~= session or not view:is_open() then
      return
    end
    for row = 1, vim.api.nvim_buf_line_count(view.win.buf) do
      local item = view:at({ row, 0 }).item
      if item and item.item == selected then
        vim.api.nvim_win_set_cursor(view.win.win, { row, 0 })
        break
      end
    end

    map("n", "r", function()
      local item = view:at().item
      if
        current == session
        and item
        and vim.tbl_contains(session.matches, item.item)
      then
        replace(session, { item.item }, false)
      end
    end, { buffer = view.win.buf, desc = "Replace occurrence" })
    map("n", "R", function()
      if current == session then
        replace(session, vim.list_slice(session.matches), true)
      end
    end, {
      buffer = view.win.buf,
      desc = "Replace all remaining occurrences",
    })
  end)
end

return M
