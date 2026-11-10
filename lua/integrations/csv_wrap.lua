-- Adapt csvview's parsed fields to render-markdown's concealed-row/virtual-line
-- approach. The cursor row stays real text: insert, motions, undo and writes
-- continue to operate on the original CSV, with native wrapping.
local M = {}

local function wrap(text, width)
  local lines, line = {}, ""
  for _, ch in ipairs(vim.fn.split(text, "\\zs")) do
    if ch == "\t" then
      ch = " "
    end
    if line ~= "" and vim.fn.strdisplaywidth(line .. ch) > width then
      lines[#lines + 1], line = line, ""
    end
    line = line .. ch
  end
  lines[#lines + 1] = line
  return lines
end

local function layout(view, width)
  local widths, total = {}, 1
  for i = 1, view.metrics:column_count() do
    widths[i] = math.max(1, math.min(view.metrics:column(i).max_width, 40))
    total = total + widths[i] + 3
  end
  -- Shrink the widest columns first; short identifiers retain their space.
  while total > width do
    local widest
    for i, value in ipairs(widths) do
      if value > 2 and (not widest or value > widths[widest]) then
        widest = i
      end
    end
    if not widest then
      return nil -- Too many columns: show labeled fields vertically instead.
    end
    widths[widest], total = widths[widest] - 1, total - 1
  end
  return widths
end

local function render(view, row, source, widths, width)
  local cells, height = {}, 1
  for i, field in row:iter() do
    cells[i] = wrap(
      source:sub(field.offset + 1, field.offset + field.len),
      widths and widths[i] or math.max(2, width - 8)
    )
    height = math.max(height, #cells[i])
  end
  local lines = {}
  if not widths then
    for i = 1, view.metrics:column_count() do
      for fragment, text in ipairs(cells[i] or { "" }) do
        lines[#lines + 1] = {
          {
            fragment == 1 and string.format("%5d │ ", i) or "      │ ",
            "CsvViewDelimiter",
          },
          { text, "CsvViewCol" .. (i - 1) % 9 },
        }
      end
    end
    return lines
  end
  for fragment = 1, height do
    local chunks = { { "│", "CsvViewDelimiter" } }
    for i, size in ipairs(widths) do
      local text = (cells[i] or {})[fragment] or ""
      chunks[#chunks + 1] = {
        " " .. text .. string.rep(
          " ",
          math.max(0, size - vim.fn.strdisplaywidth(text))
        ) .. " ",
        "CsvViewCol" .. (i - 1) % 9,
      }
      chunks[#chunks + 1] = { "│", "CsvViewDelimiter" }
    end
    lines[#lines + 1] = chunks
  end
  return lines
end

function M.setup()
  if M.loaded or vim.fn.has "nvim-0.11" == 0 then
    return
  end
  M.loaded = true
  local View = require("csvview.view").View
  local original_clear, original_setup, original_dispose =
    View.clear, View.setup_window, View.dispose
  local saved = {}

  function View:setup_window(win)
    if not saved[win] then
      saved[win] = {}
      for _, name in ipairs {
        "wrap",
        "linebreak",
        "breakindent",
        "showbreak",
        "conceallevel",
        "concealcursor",
      } do
        saved[win][name] = vim.wo[win][name]
      end
    end
    original_setup(self, win)
    vim.wo[win].wrap = true
    vim.wo[win].linebreak = true
    vim.wo[win].breakindent = false
    vim.wo[win].showbreak = ""
    vim.wo[win].conceallevel = 2
    vim.wo[win].concealcursor = "nvic"
  end

  function View:clear()
    self._wrap_signature = nil
    original_clear(self)
  end

  function View:dispose()
    original_dispose(self)
    for _, win in ipairs(vim.fn.win_findbuf(self.bufnr)) do
      if saved[win] then
        for name, value in pairs(saved[win]) do
          vim.wo[win][name] = value
        end
        saved[win] = nil
      end
    end
  end

  function View:render_lines()
    local width, active = math.huge, {}
    for _, win in ipairs(vim.fn.win_findbuf(self.bufnr)) do
      local info = vim.fn.getwininfo(win)[1]
      width = math.min(width, math.max(10, info.width - info.textoff))
      active[vim.api.nvim_win_get_cursor(win)[1]] = true
    end
    if width == math.huge then
      return
    end
    local signature = vim.inspect {
      width,
      active,
      vim.api.nvim_buf_get_changedtick(self.bufnr),
    }
    if self._wrap_signature == signature then
      return
    end
    self:clear()
    local widths = layout(self, width)
    local source = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
    local pending = {}
    local function flush(anchor)
      if #pending > 0 then
        self:_add_extmark(
          anchor,
          0,
          { virt_lines = pending, virt_lines_above = true, strict = false }
        )
        pending = {}
      end
    end
    for lnum, text in ipairs(source) do
      local row = self.metrics:row { lnum = lnum }
      if not row or row.type == "comment" or active[lnum] then
        flush(lnum)
        if row then
          if row.type == "comment" then
            self:_highlight_comment(lnum)
          else
            for i, field in row:iter() do
              self:_highlight_field(lnum, i, field)
            end
          end
        end
      else
        self:_add_extmark(
          lnum,
          0,
          { end_row = lnum, end_col = 0, conceal_lines = "" }
        )
        vim.list_extend(pending, render(self, row, text, widths, width))
      end
    end
    flush(#source + 1)
    self._wrap_signature = signature
  end

  -- Reveal the newly entered source row before redraw, including insert-mode
  -- changes and split-window cursors. csvview handles parsing and text updates.
  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "WinEnter", "WinResized", "VimResized" },
    {
      group = vim.api.nvim_create_augroup("CsvWrap", { clear = true }),
      callback = function()
        local view = require("csvview.view").get(vim.api.nvim_get_current_buf())
        if view and not view:is_locked() then
          view:render_lines()
        end
      end,
    }
  )
end

return M
