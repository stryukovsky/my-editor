local MiniDiff = require "mini.diff"
local notify = require "configs.notify"

local M = {}

local NS = vim.api.nvim_create_namespace "LargeHunkViewer"

local WORDDIFF_OPTS = {
  algorithm = "minimal",
  result_type = "indices",
  ctxlen = 0,
  interhunkctxlen = 4,
  indent_heuristic = false,
  linematch = 0,
}

local LINE_DIFF_OPTS = {
  algorithm = "histogram",
  result_type = "indices",
  indent_heuristic = true,
  linematch = 60,
}

---@param hunk table
---@return integer, integer
local function hunk_buf_range(hunk)
  if hunk.buf_count > 0 then
    return hunk.buf_start, hunk.buf_start + hunk.buf_count - 1
  end
  local from = math.max(hunk.buf_start, 1)
  return from, from
end

---@param buf integer
---@return table|nil hunk
---@return table|nil data
local function hunk_at_cursor(buf)
  local data = MiniDiff.get_buf_data(buf)
  if not data or not data.hunks then
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  for _, hunk in ipairs(data.hunks) do
    local from, to = hunk_buf_range(hunk)
    if lnum >= from and lnum <= to then
      return hunk, data
    end
  end
end

---@return string
local function unique_name()
  for _ = 1, 50 do
    local name = string.format("hunk_%d", math.random(100, 999))
    if vim.fn.bufexists(name) == 0 then
      return name
    end
  end
  return string.format("hunk_%d", math.random(100, 999))
end

---@param buf integer
local function lock_buf(buf)
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].undofile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].modified = false
  vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd", "FileAppendCmd" }, {
    buffer = buf,
    callback = function()
      notify.send("Hunk viewer", "Hunk buffers cannot be saved", vim.log.levels.WARN)
    end,
  })
end

---@param win integer
local function apply_window(win)
  if not vim.api.nvim_win_is_valid(win) then
    return
  end
  -- No gutter / breakindent: wrap must start at column 0 (no uncolored left pad).
  vim.wo[win].statuscolumn = ""
  vim.wo[win].signcolumn = "no"
  vim.wo[win].foldcolumn = "0"
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = false
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = false
  vim.wo[win].breakindent = false
  vim.wo[win].showbreak = ""
end

---@param line string
---@return string, integer[], integer[]
local function slice_line(line)
  line = line or ""
  local line_len = #line
  if line_len == 0 then
    return "\n", {}, {}
  end
  if vim.str_utfindex(line, "utf-32") == line_len then
    local starts, ends = {}, {}
    for i = 1, line_len do
      starts[i], ends[i] = i, i
    end
    return (line:gsub(".", "%1\n")), starts, ends
  end
  local starts = vim.str_utf_pos(line)
  if not starts or #starts == 0 then
    return "\n", {}, {}
  end
  local parts, ends = {}, {}
  for i = 1, #starts - 1 do
    parts[#parts + 1] = line:sub(starts[i], starts[i + 1] - 1)
    ends[#ends + 1] = starts[i + 1] - 1
  end
  parts[#parts + 1] = line:sub(starts[#starts], line_len)
  ends[#ends + 1] = line_len
  return table.concat(parts, "\n") .. "\n", starts, ends
end

---@param old_line string
---@param new_line string
---@return integer[][] old_ranges
---@return integer[][] new_ranges
local function word_ranges(old_line, new_line)
  local old_sliced, old_starts, old_ends = slice_line(old_line)
  local new_sliced, new_starts, new_ends = slice_line(new_line)
  local diff = vim.diff(old_sliced, new_sliced, WORDDIFF_OPTS)
  local old_ranges, new_ranges = {}, {}
  for _, d in ipairs(diff) do
    if d[2] > 0 then
      old_ranges[#old_ranges + 1] = { old_starts[d[1]], old_ends[d[1] + d[2] - 1] }
    end
    if d[4] > 0 then
      new_ranges[#new_ranges + 1] = { new_starts[d[3]], new_ends[d[3] + d[4] - 1] }
    end
  end
  return old_ranges, new_ranges
end

---@param buf integer
---@param row0 integer
---@param hl string
---@param priority integer
local function hl_line(buf, row0, hl, priority)
  vim.api.nvim_buf_set_extmark(buf, NS, row0, 0, {
    end_row = row0 + 1,
    end_col = 0,
    hl_group = hl,
    hl_eol = true,
    hl_mode = "combine",
    priority = priority,
  })
end

---@param buf integer
---@param row0 integer
---@param from integer
---@param to integer
---@param hl string
---@param priority integer
local function hl_span(buf, row0, from, to, hl, priority)
  if not from or not to or to < from then
    return
  end
  vim.api.nvim_buf_set_extmark(buf, NS, row0, from - 1, {
    end_row = row0,
    end_col = to,
    hl_group = hl,
    hl_mode = "combine",
    priority = priority,
  })
end

---@param old_lines string[]
---@param new_lines string[]
---@return { old_from: integer, old_count: integer, new_from: integer, new_count: integer }[]
local function align_hunks(old_lines, new_lines)
  if #old_lines == 0 or #new_lines == 0 then
    return { { old_from = 1, old_count = #old_lines, new_from = 1, new_count = #new_lines } }
  end
  local diff = vim.diff(table.concat(old_lines, "\n") .. "\n", table.concat(new_lines, "\n") .. "\n", LINE_DIFF_OPTS)
  local hunks = {}
  for _, d in ipairs(diff) do
    hunks[#hunks + 1] = {
      old_from = d[1],
      old_count = d[2],
      new_from = d[3],
      new_count = d[4],
    }
  end
  return hunks
end

---@param buf integer
---@param old_lines string[]
---@param new_lines string[]
local function apply_highlights(buf, old_lines, new_lines)
  local new_row0 = #old_lines
  for i = 1, #old_lines do
    hl_line(buf, i - 1, "MiniDiffOverDelete", 10)
  end
  for i = 1, #new_lines do
    hl_line(buf, new_row0 + i - 1, "MiniDiffOverAdd", 10)
  end

  for _, aligned in ipairs(align_hunks(old_lines, new_lines)) do
    if aligned.old_count > 0 and aligned.new_count > 0 and aligned.old_count == aligned.new_count then
      for i = 0, aligned.old_count - 1 do
        local old_line = old_lines[aligned.old_from + i] or ""
        local new_line = new_lines[aligned.new_from + i] or ""
        local old_spans, new_spans = word_ranges(old_line, new_line)
        local old_row = aligned.old_from + i - 1
        local new_row = new_row0 + aligned.new_from + i - 1
        for _, span in ipairs(old_spans) do
          hl_span(buf, old_row, span[1], span[2], "MiniDiffOverChange", 20)
        end
        for _, span in ipairs(new_spans) do
          hl_span(buf, new_row, span[1], span[2], "MiniDiffOverChangeBuf", 20)
        end
      end
    end
  end
end

---@param buf integer
local function detach_lsp(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  for _, client in ipairs(vim.lsp.get_clients { bufnr = buf }) do
    pcall(vim.lsp.buf_detach_client, buf, client.id)
  end
  pcall(vim.diagnostic.enable, false, { bufnr = buf })
end

function M.view_hunk()
  local src = vim.api.nvim_get_current_buf()
  if vim.b[src].large_hunk_viewer then
    return
  end

  local hunk, data = hunk_at_cursor(src)
  if not hunk or not data then
    notify.send("Hunk viewer", "No hunk under cursor", vim.log.levels.INFO)
    return
  end

  local old_lines = {}
  if hunk.ref_count > 0 and type(data.ref_text) == "string" then
    local ref_lines = vim.split(data.ref_text, "\n", { plain = true })
    for i = hunk.ref_start, hunk.ref_start + hunk.ref_count - 1 do
      old_lines[#old_lines + 1] = ref_lines[i] or ""
    end
  end

  local new_lines = {}
  if hunk.buf_count > 0 then
    local start0 = math.max(hunk.buf_start - 1, 0)
    new_lines = vim.api.nvim_buf_get_lines(src, start0, start0 + hunk.buf_count, false)
  end

  ---@type string[]
  local lines = {}
  for _, line in ipairs(old_lines) do
    lines[#lines + 1] = line
  end
  for _, line in ipairs(new_lines) do
    lines[#lines + 1] = line
  end

  if #lines == 0 then
    notify.send("Hunk viewer", "Hunk is empty", vim.log.levels.INFO)
    return
  end

  local buf = vim.api.nvim_create_buf(true, false)
  vim.b[buf].large_hunk_viewer = true
  vim.b[buf].minidiff_disable = true

  pcall(vim.api.nvim_buf_set_name, buf, unique_name())
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = ""
  vim.bo[buf].syntax = ""
  apply_highlights(buf, old_lines, new_lines)

  lock_buf(buf)
  detach_lsp(buf)
  vim.api.nvim_set_current_buf(buf)
  apply_window(vim.api.nvim_get_current_win())
end

function M.setup()
  local group = vim.api.nvim_create_augroup("LargeHunkViewer", { clear = true })

  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      if vim.b[ev.buf].large_hunk_viewer then
        vim.schedule(function()
          detach_lsp(ev.buf)
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function(ev)
      if vim.b[ev.buf].large_hunk_viewer then
        apply_window(vim.api.nvim_get_current_win())
      end
    end,
  })
end

return M
