local M = {}
local ns = vim.api.nvim_create_namespace "scalar_lines"
local session

local function tell(message)
  vim.notify("Scalar lines: " .. message)
end

local function normal(keys)
  vim.cmd.normal { args = { keys }, bang = true }
end

local function leave_visual()
  if vim.fn.mode():match "^[vV\22]" then
    normal(vim.api.nvim_replace_termcodes("<Esc>", true, false, true))
  end
end

local function on_blank_line()
  return vim.api.nvim_get_current_line():match "^%s*$" ~= nil
end

local function position(element)
  local p = vim.api.nvim_buf_get_extmark_by_id(
    session.buf,
    ns,
    element.mark,
    { details = true }
  )
  return p[1], p[2], p[3].end_col
end

local function show(element)
  local row, first, last = position(element)
  leave_visual()
  vim.api.nvim_win_set_cursor(0, { row + 1, first })
  normal "v"
  local line = vim.api.nvim_get_current_line()
  local tail = line:sub(1, last)
  local start = tail:find "[\192-\255][\128-\191]*$"
  vim.api.nvim_win_set_cursor(
    0,
    { row + 1, start and start - 1 or math.max(first, last - 1) }
  )
end

local function save()
  local mode = vim.fn.mode()
  if mode ~= "v" then
    tell "Select a single-line character range first (viw selects a word)."
    return false
  end
  local anchor, cursor = vim.fn.getpos "v", vim.api.nvim_win_get_cursor(0)
  if anchor[2] ~= cursor[1] then
    tell "Each element must fit on one line."
    return false
  end
  local row = cursor[1] - 1
  local first, last =
    math.min(anchor[3] - 1, cursor[2]), math.max(anchor[3] - 1, cursor[2])
  local line = vim.api.nvim_get_current_line()
  if vim.o.selection == "exclusive" and first ~= last then
    -- Exclusive selection excludes the cursor end, whichever direction it faces.
    if cursor[2] > anchor[3] - 1 then
      last = last - 1
    else
      first = first
        + #(line:sub(first + 1):match "^[%z\1-\127\194-\244][\128-\191]*" or "")
    end
  end
  local char = line:sub(last + 1):match "^[%z\1-\127\194-\244][\128-\191]*"
    or ""
  last = math.min(#line, last + #char)
  if last <= first then
    tell "Cannot store an empty selection."
    return false
  end
  local vector = session[session.phase]
  local old = vector[session.index]
  local mark = vim.api.nvim_buf_set_extmark(session.buf, ns, row, first, {
    id = old and old.mark or nil,
    end_row = row,
    end_col = last,
    right_gravity = false,
    end_right_gravity = true,
    hl_group = session.phase == "source" and "ScalarLinesSource"
      or "ScalarLinesTarget",
    priority = 250,
  })
  vector[session.index] = { mark = mark, text = line:sub(first + 1, last) }
  return true
end

function M.cancel(buf)
  if not session or (buf and session.buf ~= buf) then
    return
  end
  leave_visual()
  if vim.api.nvim_buf_is_valid(session.buf) then
    vim.api.nvim_buf_clear_namespace(session.buf, ns, 0, -1)
    for _, saved in ipairs(session.maps) do
      pcall(vim.keymap.del, saved.mode, saved.key, { buffer = session.buf })
      if saved.previous then
        vim.api.nvim_buf_call(session.buf, function()
          vim.fn.mapset(saved.mode, false, saved.previous)
        end)
      end
    end
  end
  session = nil
end

function M.remove()
  if not session or vim.api.nvim_get_current_buf() ~= session.buf then
    return
  end
  local vector = session[session.phase]
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  local removed
  for i = #vector, 1, -1 do
    if position(vector[i]) == row then
      vim.api.nvim_buf_del_extmark(session.buf, ns, vector[i].mark)
      table.remove(vector, i)
      removed = i
    end
  end
  leave_visual()
  if removed then
    session.index = math.min(removed, math.max(1, #vector))
    if vector[session.index] then
      show(vector[session.index])
    end
    tell "Removed current line selection."
  else
    session.index = #vector + 1
    tell "Current selection discarded; select another element to continue."
  end
end

function M.step(direction)
  if not session or vim.api.nvim_get_current_buf() ~= session.buf then
    return
  end
  local blank = on_blank_line()
  if blank and direction == 1 then
    M.dot()
    return
  end
  if not blank and not save() then
    return
  end
  local vector = session[session.phase]
  local next_index = blank and math.min(session.index - 1, #vector)
    or session.index + direction
  if next_index < 1 then
    tell "Already at the first element."
    return
  end
  if session.phase == "target" and next_index > #session.source then
    local row = position(vector[session.index])
    local following =
      vim.api.nvim_buf_get_lines(session.buf, row + 1, row + 2, false)[1]
    if not following or not following:match "^%s*$" then
      tell "All target elements selected; press <leader>dots to apply."
      return
    end
  end
  if vector[next_index] then
    session.index = next_index
    show(vector[next_index])
  else
    local row, col = position(vector[session.index])
    if row + 1 >= vim.api.nvim_buf_line_count(session.buf) then
      tell "Already on the last line."
      return
    end
    session.index = next_index
    leave_visual()
    local line =
      vim.api.nvim_buf_get_lines(session.buf, row + 1, row + 2, false)[1]
    vim.api.nvim_win_set_cursor(
      0,
      { row + 2, math.min(col, math.max(0, #line - 1)) }
    )
    if not on_blank_line() then
      normal "viw"
    end
  end
end

local function start()
  session = {
    buf = vim.api.nvim_get_current_buf(),
    phase = "source",
    index = 1,
    source = {},
    target = {},
    maps = {},
  }
  local map = require "mappings.map"
  for _, mode in ipairs { "n", "x" } do
    for key, action in pairs {
      ["<C-A-j>"] = function()
        M.step(1)
      end,
      ["<C-A-k>"] = function()
        M.step(-1)
      end,
    } do
      local previous = vim.fn.maparg(key, mode, false, true)
      table.insert(session.maps, {
        mode = mode,
        key = key,
        previous = previous.buffer == 1 and previous or nil,
      })
      map(
        mode,
        key,
        action,
        { buffer = session.buf, desc = "Scalar lines: select adjacent element" }
      )
    end
  end
  if vim.fn.mode() ~= "v" then
    normal "viw"
  end
  tell "Select source values; <C-A-j>/<C-A-k> navigate, <leader>dots finishes the vector."
end

function M.dot()
  if not session then
    start()
    return
  end
  if vim.api.nvim_get_current_buf() ~= session.buf then
    tell "Return to the buffer where the operation started, or :ScalarLinesCancel."
    return
  end
  if not on_blank_line() and not save() then
    return
  end
  if session.phase == "source" then
    if #session.source == 0 then
      tell "Select at least one source value first."
      return
    end
    leave_visual()
    session.phase, session.index = "target", 1
    tell "Select the first replacement range, then use <C-A-j>; <leader>dots applies."
    return
  end
  if #session.target ~= #session.source then
    tell(
      ("Need %d targets; currently have %d."):format(
        #session.source,
        #session.target
      )
    )
    return
  end
  if not vim.bo[session.buf].modifiable then
    tell "Buffer is not modifiable."
    return
  end
  local edits = {}
  for i, element in ipairs(session.target) do
    local row, first, last = position(element)
    edits[#edits + 1] =
      { row = row, first = first, last = last, text = session.source[i].text }
  end
  table.sort(edits, function(a, b)
    return a.row == b.row and a.first > b.first or a.row > b.row
  end)
  for i = 2, #edits do
    if
      edits[i].row == edits[i - 1].row and edits[i].last > edits[i - 1].first
    then
      tell "Target selections overlap; adjust them before applying."
      return
    end
  end
  leave_visual()
  for i, edit in ipairs(edits) do
    if i > 1 then
      vim.cmd.undojoin()
    end
    vim.api.nvim_buf_set_text(
      session.buf,
      edit.row,
      edit.first,
      edit.row,
      edit.last,
      { edit.text }
    )
  end
  M.cancel()
  tell(("Replaced %d elements."):format(#edits))
end

return M
