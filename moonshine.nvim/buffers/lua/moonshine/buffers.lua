local M = {}
local order = {}

function M.refresh()
  require("lualine").refresh { place = { "tabline" } }
end

function M.list()
  local buffers, seen = {}, {}
  local function add(buf)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype ~= "quickfix" then
      buffers[#buffers + 1] = buf
      seen[buf] = true
    end
  end
  for _, buf in ipairs(order) do
    add(buf)
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if not seen[buf] then
      add(buf)
    end
  end
  order = buffers
  return buffers
end

function M.is_pinned(buf)
  return vim.api.nvim_buf_is_valid(buf) and vim.b[buf].buffer_pinned == true
end

function M.toggle_pin(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  vim.b[buf].buffer_pinned = not M.is_pinned(buf)
  M.refresh()
end

function M.navigate(direction)
  local buffers = M.list()
  if #buffers == 0 then
    return
  end
  local index = 0
  for i, buf in ipairs(buffers) do
    if buf == vim.api.nvim_get_current_buf() then
      index = i
      break
    end
  end
  vim.api.nvim_set_current_buf(buffers[(index - 1 + direction * vim.v.count1) % #buffers + 1])
end

function M.move(direction)
  local buffers = M.list()
  for i, buf in ipairs(buffers) do
    if buf == vim.api.nvim_get_current_buf() then
      local target = math.max(1, math.min(#buffers, i + direction * vim.v.count1))
      table.remove(buffers, i)
      table.insert(buffers, target, buf)
      break
    end
  end
  M.refresh()
end

function M.pick()
  vim.ui.select(M.list(), {
    prompt = "Buffer",
    format_item = function(buf)
      local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
      return ("%s%s"):format(M.is_pinned(buf) and " " or "", name ~= "" and name or "[No Name]")
    end,
  }, function(buf)
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_set_current_buf(buf)
    end
  end)
end

--- Force-close a buffer without closing its windows.
function M.close_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  local replacement
  for _, candidate in ipairs(M.list()) do
    if candidate ~= buf then
      replacement = candidate
      break
    end
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    replacement = replacement or vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win, replacement)
  end
  vim.api.nvim_buf_delete(buf, { force = true })
  M.refresh()
end

function M.close_buffers(buffers)
  for _, buf in pairs(buffers or {}) do
    M.close_buffer(buf)
  end
end

--- Keep the current buffer, terminals, pinned buffers, and unsaved changes.
function M.close_unprotected()
  local buffers = {}
  for _, buf in ipairs(M.list()) do
    if buf ~= vim.api.nvim_get_current_buf() and not M.is_pinned(buf) and vim.bo[buf].buftype ~= "terminal" and not vim.bo[buf].modified then
      buffers[#buffers + 1] = buf
    end
  end
  M.close_buffers(buffers)
  local message = #buffers == 0 and "Nothing to close" or ("Closed %d buffer%s"):format(#buffers, #buffers == 1 and "" or "s")
  require("integrations.notify").send("Buffers", message, vim.log.levels.INFO)
end

--- Reuse lualine's renderer, with the same ordering as navigation shortcuts.
function M.component()
  local base = require "lualine.components.buffers"
  local component = base:extend()
  function component:init(options)
    options.component_name = "buffers"
    base.init(self, options)
  end
  function component:buffers()
    local buffers = {}
    base.bufpos2nr = M.list()
    for i, buf in ipairs(base.bufpos2nr) do
      buffers[i] = self:new_buffer(buf, i)
    end
    return buffers
  end
  return component
end

return M
