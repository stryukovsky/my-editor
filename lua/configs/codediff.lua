local is_codediff_tab = require "utils.is_codediff_tab"

local M = {}

-- Shared wrap preference. Normal buffers stay `nowrap` until toggled;
-- CodeDiff views follow this flag (plugin itself forces nowrap on render).
if vim.g.wrap == nil then
  vim.g.wrap = true
end

M.opts = {
  highlights = {
    -- char_insert = "#22bb22", -- Character-level insertions (nil = auto-derive)
    -- char_delete = "#ffaabb", -- Character-level deletions (nil = auto-derive)
  },
  diff = {
    layout = "inline",
    disable_inlay_hints = true,
  },
  explorer = {
    focus_on_select = false,
    view_mode = "tree",
  },
  keymaps = {
    view = {
      quit = "q", -- Close diff tab
      toggle_explorer = "<leader>b", -- Toggle explorer visibility (explorer mode only)
      focus_explorer = "<A-e>", -- Focus explorer panel (explorer mode only)
      next_hunk = "]g", -- Jump to next change
      prev_hunk = "[g", -- Jump to previous change
      next_file = "]f", -- Next file in explorer/history mode
      prev_file = "[f", -- Previous file in explorer/history mode
      open_in_prev_tab = "o", -- Open current buffer in previous tab (or create one before)
      close_on_open_in_prev_tab = true, -- Close codediff tab after gf opens file in previous tab
      -- stage_hunk = "<leader>gs", -- Stage hunk under cursor to git index
      unstage_hunk = "<leader>gu", -- Unstage hunk under cursor from git index
      discard_hunk = "<leader>gr", -- Discard hunk under cursor (working tree only)
      hunk_textobject = "ih", -- Textobject for hunk (vih to select, yih to yank, etc.)
      show_help = "g?", -- Show floating window with available keymaps
      align_move = "gm", -- Temporarily align moved code blocks across panes
      toggle_layout = "t", -- Toggle between side-by-side and inline layout
      toggle_compact = "gc", -- Toggle compact mode (fold unchanged regions)
      toggle_stage = "s",
    },
    explorer = {
      select = "<CR>",
    },
  },
}

local BANNER_TEXT = "You are in Codediff mode"
local banner_win ---@type integer|nil
local banner_buf ---@type integer|nil

local plugin_patched = false
local inline_ns ---@type integer|nil

---@class CodeDiffVirtSnap
---@field id integer
---@field row integer
---@field col integer
---@field virt_lines table
---@field virt_lines_above boolean|nil
---@field virt_lines_overflow string|nil
---@field priority integer|nil

---@type table<integer, CodeDiffVirtSnap[]>
local virt_snapshots = {}

---@param win integer
---@return boolean
local function is_real_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  local cfg = vim.api.nvim_win_get_config(win)
  return cfg.relative == ""
end

---@param win integer
---@param enabled boolean
local function set_win_wrap(win, enabled)
  vim.wo[win].wrap = enabled
  vim.wo[win].linebreak = enabled
  vim.wo[win].breakindent = enabled
end

---@param buf integer
---@return integer
local function view_width(buf)
  local tab = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      local info = vim.fn.getwininfo(win)[1]
      if info then
        return math.max(1, info.width - info.textoff)
      end
    end
  end
  return math.max(1, vim.o.columns)
end

---@param chunk table
---@return boolean
local function is_eol_pad(chunk)
  local text = chunk and chunk[1]
  return type(text) == "string" and #text >= 100 and text:find "^%s+$" ~= nil
end

---@param text string
---@param maxw integer
---@return string, string
local function split_display(text, maxw)
  if maxw < 1 then
    maxw = 1
  end
  if text == "" or vim.fn.strdisplaywidth(text) <= maxw then
    return text, ""
  end
  local chars = vim.fn.strchars(text)
  local lo, hi = 0, chars
  while lo < hi do
    local mid = math.floor((lo + hi + 1) / 2)
    if vim.fn.strdisplaywidth(vim.fn.strcharpart(text, 0, mid)) <= maxw then
      lo = mid
    else
      hi = mid - 1
    end
  end
  if lo < 1 then
    lo = 1
  end
  return vim.fn.strcharpart(text, 0, lo), vim.fn.strcharpart(text, lo)
end

---@param chunks table
---@return table, string
local function strip_eol_pad(chunks)
  local last = chunks[#chunks]
  local base_hl = (last and last[2]) or "CodeDiffLineDelete"
  if last and is_eol_pad(last) then
    local trimmed = {}
    for i = 1, #chunks - 1 do
      trimmed[i] = chunks[i]
    end
    if #trimmed == 0 then
      trimmed = { { "", base_hl } }
    end
    return trimmed, base_hl
  end
  return chunks, base_hl
end

---@param row table
---@param width integer
---@param base_hl string
---@return table
local function pad_row(row, width, base_hl)
  local used = 0
  for _, chunk in ipairs(row) do
    used = used + vim.fn.strdisplaywidth(chunk[1] or "")
  end
  if used < width then
    row[#row + 1] = { string.rep(" ", width - used), base_hl }
  end
  return row
end

---@param chunks table
---@param width integer
---@return table
local function wrap_one_virt_line(chunks, width)
  local stripped, base_hl = strip_eol_pad(chunks)
  local rows = {}
  local row = {}
  local used = 0

  local function flush()
    if #row == 0 then
      row = { { "", base_hl } }
    end
    rows[#rows + 1] = pad_row(row, width, base_hl)
    row = {}
    used = 0
  end

  for _, chunk in ipairs(stripped) do
    local rest = chunk[1] or ""
    local hl = chunk[2] or base_hl
    if rest == "" then
      if #row == 0 then
        row[1] = { "", hl }
      end
    else
      while rest ~= "" do
        local space = width - used
        if space < 1 then
          flush()
          space = width
        end
        local prefix, leftover = split_display(rest, space)
        row[#row + 1] = { prefix, hl }
        used = used + vim.fn.strdisplaywidth(prefix)
        rest = leftover
        if rest ~= "" then
          flush()
        end
      end
    end
  end
  flush()
  return rows
end

---@param virt_lines table
---@param width integer
---@return table
local function wrap_all_virt_lines(virt_lines, width)
  local out = {}
  for _, chunks in ipairs(virt_lines) do
    for _, row in ipairs(wrap_one_virt_line(chunks, width)) do
      out[#out + 1] = row
    end
  end
  return out
end

---@param buf integer
local function snapshot_virt_lines(buf)
  if not inline_ns or not vim.api.nvim_buf_is_valid(buf) then
    virt_snapshots[buf] = nil
    return
  end
  local marks = vim.api.nvim_buf_get_extmarks(buf, inline_ns, 0, -1, { details = true })
  local snap = {}
  for _, mark in ipairs(marks) do
    local details = mark[4]
    if details and details.virt_lines and #details.virt_lines > 0 then
      snap[#snap + 1] = {
        id = mark[1],
        row = mark[2],
        col = mark[3],
        virt_lines = vim.deepcopy(details.virt_lines),
        virt_lines_above = details.virt_lines_above,
        virt_lines_overflow = details.virt_lines_overflow,
        priority = details.priority,
      }
    end
  end
  virt_snapshots[buf] = snap
end

---@param buf integer
---@param enabled? boolean
local function apply_virt_wrap(buf, enabled)
  if enabled == nil then
    enabled = vim.g.wrap ~= false
  end
  local snap = virt_snapshots[buf]
  if not snap or not inline_ns or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local width = view_width(buf)
  local overflow_off = vim.fn.has "nvim-0.11" == 1 and "trunc" or nil
  for _, mark in ipairs(snap) do
    local lines = vim.deepcopy(mark.virt_lines)
    local overflow = mark.virt_lines_overflow
    if enabled then
      lines = wrap_all_virt_lines(lines, width)
      overflow = overflow_off
    end
    pcall(vim.api.nvim_buf_set_extmark, buf, inline_ns, mark.row, mark.col, {
      id = mark.id,
      virt_lines = lines,
      virt_lines_above = mark.virt_lines_above,
      virt_lines_overflow = overflow,
      priority = mark.priority,
    })
  end
end

---Apply the global wrap preference to every real window in the CodeDiff tab.
---@param enabled? boolean
function M.apply_wrap(enabled)
  if enabled == nil then
    enabled = vim.g.wrap ~= false
  end
  if not is_codediff_tab() then
    return
  end
  local seen = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_real_win(win) then
      set_win_wrap(win, enabled)
      local buf = vim.api.nvim_win_get_buf(win)
      if not seen[buf] then
        seen[buf] = true
        apply_virt_wrap(buf, enabled)
      end
    end
  end
end

---@param buf integer
---@return boolean
local function is_codediff_owned_buf(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  local name = vim.api.nvim_buf_get_name(buf)
  if name:find("codediff://", 1, true) then
    return true
  end
  local ft = vim.bo[buf].filetype
  if ft:find "^codediff" then
    return true
  end
  local bt = vim.bo[buf].buftype
  return (bt == "nofile" or bt == "nowrite") and is_codediff_tab()
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

---Monkey-patch codediff after the plugin is on rtp. Safe to call more than once.
function M.patch_plugin()
  if plugin_patched then
    return
  end
  local ok_inline, inline = pcall(require, "codediff.ui.inline")
  if not ok_inline then
    return
  end
  plugin_patched = true
  inline_ns = inline.ns_inline
  local orig_render = inline.render_inline_diff
  inline.render_inline_diff = function(bufnr, ...)
    orig_render(bufnr, ...)
    snapshot_virt_lines(bufnr)
    apply_virt_wrap(bufnr)
  end
  local ok_sem, semantic = pcall(require, "codediff.ui.semantic_tokens")
  if ok_sem then
    semantic.apply_semantic_tokens = function() end
  end
end

local function banner_line()
  local width = vim.o.columns
  local text_w = vim.fn.strdisplaywidth(BANNER_TEXT)
  local pad = math.max(0, math.floor((width - text_w) / 2))
  return string.rep(" ", pad) .. BANNER_TEXT
end

local function close_banner()
  if banner_win and vim.api.nvim_win_is_valid(banner_win) then
    pcall(vim.api.nvim_win_close, banner_win, true)
  end
  if banner_buf and vim.api.nvim_buf_is_valid(banner_buf) then
    pcall(vim.api.nvim_buf_delete, banner_buf, { force = true })
  end
  banner_win, banner_buf = nil, nil
end

local function layout_banner()
  if not (banner_win and vim.api.nvim_win_is_valid(banner_win) and banner_buf and vim.api.nvim_buf_is_valid(banner_buf)) then
    return
  end
  vim.bo[banner_buf].modifiable = true
  vim.api.nvim_buf_set_lines(banner_buf, 0, -1, false, { banner_line() })
  vim.bo[banner_buf].modifiable = false
  pcall(vim.api.nvim_win_set_config, banner_win, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = 1,
  })
end

local function open_banner()
  vim.api.nvim_set_hl(0, "CodeDiffModeBanner", { link = "Title", default = true })
  if banner_win and vim.api.nvim_win_is_valid(banner_win) then
    layout_banner()
    return
  end
  banner_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[banner_buf].bufhidden = "wipe"
  vim.bo[banner_buf].buftype = "nofile"
  vim.bo[banner_buf].modifiable = true
  vim.api.nvim_buf_set_lines(banner_buf, 0, -1, false, { banner_line() })
  vim.bo[banner_buf].modifiable = false
  banner_win = vim.api.nvim_open_win(banner_buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = 1,
    style = "minimal",
    focusable = false,
    zindex = 200,
    border = "none",
  })
  vim.wo[banner_win].winhl = "Normal:CodeDiffModeBanner"
  vim.wo[banner_win].wrap = false
  vim.wo[banner_win].cursorline = false
  vim.wo[banner_win].number = false
  vim.wo[banner_win].relativenumber = false
  vim.wo[banner_win].signcolumn = "no"
  vim.wo[banner_win].foldcolumn = "0"
  vim.wo[banner_win].statuscolumn = ""
end

local function enter_mode()
  M.patch_plugin()
  open_banner()
  M.apply_wrap()
end

local function leave_mode()
  close_banner()
end

local group = vim.api.nvim_create_augroup("CodeDiffMode", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = { "CodeDiffOpen", "CodeDiffFileSelect" },
  callback = function()
    vim.schedule(enter_mode)
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "CodeDiffClose",
  callback = function()
    vim.schedule(function()
      if is_codediff_tab() then
        enter_mode()
      else
        leave_mode()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("TabEnter", {
  group = group,
  callback = function()
    if is_codediff_tab() then
      enter_mode()
    else
      leave_mode()
    end
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "WinNew" }, {
  group = group,
  callback = function()
    if not is_codediff_tab() then
      return
    end
    vim.schedule(function()
      if is_codediff_tab() then
        M.apply_wrap()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    if is_codediff_tab() then
      layout_banner()
      M.apply_wrap()
    end
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    if is_codediff_tab() then
      M.apply_wrap()
    end
  end,
})

vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(ev)
    virt_snapshots[ev.buf] = nil
  end,
})

-- CodeDiff has no "disable LSP" option. Detach from plugin-owned buffers only
-- (codediff://, explorer/help, scratch nofile). The working-tree pane reuses
-- the real file buffer, so LSP stays attached there.
vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(ev)
    if not is_codediff_owned_buf(ev.buf) then
      return
    end
    local client_id = ev.data and ev.data.client_id
    if client_id then
      pcall(vim.lsp.buf_detach_client, ev.buf, client_id)
    else
      detach_lsp(ev.buf)
    end
    pcall(vim.diagnostic.enable, false, { bufnr = ev.buf })
  end,
})

return M
