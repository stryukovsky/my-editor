local MiniDiff = require "mini.diff"

local M = {}

local LARGE_LINE = 400
local LARGE_HUNK_LINES = 40
local LARGE_HUNK_BYTES = 8000

MiniDiff.setup {
  view = {
    style = "sign",
    signs = { add = "┃", change = "┃", delete = "▁" },
  },
  -- Default maps use vim.keymap.set; keep them off and bind via mappings.map.
  mappings = {
    apply = "",
    reset = "",
    textobject = "",
    goto_first = "",
    goto_prev = "",
    goto_next = "",
    goto_last = "",
  },
  options = {
    algorithm = "histogram",
    indent_heuristic = true,
    linematch = 0,
    wrap_goto = true,
  },
}

vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
  group = vim.api.nvim_create_augroup("MiniDiffSkipHeavy", { clear = true }),
  callback = function(ev)
    if vim.b[ev.buf].skip_heavy_operations or vim.b[ev.buf].large_file then
      vim.b[ev.buf].minidiff_disable = true
      pcall(MiniDiff.disable, ev.buf)
    end
  end,
})

---@return table|nil hunk
---@return table|nil data
local function hunk_at_cursor()
  local data = MiniDiff.get_buf_data(0)
  if not data or not data.hunks then
    return
  end
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  for _, hunk in ipairs(data.hunks) do
    local from = math.max(hunk.buf_start, 1)
    local to = hunk.buf_count > 0 and (hunk.buf_start + hunk.buf_count - 1) or from
    if lnum >= from and lnum <= to then
      return hunk, data
    end
  end
end

---@param hunk table
---@param data table
---@return boolean
local function is_large(hunk, data)
  if hunk.buf_count + hunk.ref_count > LARGE_HUNK_LINES then
    return true
  end
  local bytes = 0
  if hunk.buf_count > 0 then
    local start0 = math.max(hunk.buf_start - 1, 0)
    local lines = vim.api.nvim_buf_get_lines(0, start0, start0 + hunk.buf_count, false)
    for _, line in ipairs(lines) do
      bytes = bytes + #line
      if #line > LARGE_LINE or bytes > LARGE_HUNK_BYTES then
        return true
      end
    end
  end
  if hunk.ref_count > 0 and type(data.ref_text) == "string" then
    local ref_lines = vim.split(data.ref_text, "\n", { plain = true })
    for i = hunk.ref_start, hunk.ref_start + hunk.ref_count - 1 do
      local line = ref_lines[i] or ""
      bytes = bytes + #line
      if #line > LARGE_LINE or bytes > LARGE_HUNK_BYTES then
        return true
      end
    end
  end
  return false
end

function M.preview()
  local hunk, data = hunk_at_cursor()
  if not hunk or not data then
    return
  end
  if is_large(hunk, data) then
    vim.cmd "CodeDiff file HEAD"
    return
  end
  MiniDiff.toggle_overlay(0)
end

function M.reset_hunk()
  local line = vim.fn.line "."
  pcall(MiniDiff.do_hunks, 0, "reset", { line_start = line, line_end = line })
end

function M.reset_buffer()
  pcall(MiniDiff.do_hunks, 0, "reset")
end

function M.select()
  MiniDiff.textobject()
end

---@param dir 1|-1
function M.nav(dir)
  if vim.wo.diff then
    vim.cmd.normal { dir > 0 and "]c" or "[c", bang = true }
    return
  end
  if MiniDiff.get_buf_data(0) == nil then
    return
  end
  MiniDiff.goto_hunk(dir > 0 and "next" or "prev")
  vim.cmd "normal! zz"
  local hunk, data = hunk_at_cursor()
  if not hunk or not data then
    return
  end
  if is_large(hunk, data) then
    vim.cmd "CodeDiff file HEAD"
    return
  end
  if not data.overlay then
    MiniDiff.toggle_overlay(0)
  end
end

return M
