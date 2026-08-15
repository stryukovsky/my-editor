local MiniDiff = require "mini.diff"
local notify = require "configs.notify"

local M = {}

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
