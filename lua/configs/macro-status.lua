local M = {}
local namespace = vim.api.nvim_create_namespace "native_macro_start"
local group = vim.api.nvim_create_augroup("NativeMacroStatus", { clear = true })
local saved_bars = {}
local start_buffer
local recording = false

function M.active()
  return vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= ""
end

local function highlights()
  vim.api.nvim_set_hl(0, "MacroRecording", { fg = "#ffffff", bg = "#ff1744", bold = true })
  vim.api.nvim_set_hl(0, "MacroRecordingStart", { fg = "#ff1744", bold = true })
end

local function clear_marker()
  if start_buffer and vim.api.nvim_buf_is_valid(start_buffer) then
    vim.api.nvim_buf_clear_namespace(start_buffer, namespace, 0, -1)
  end
  start_buffer = nil
end

local function update()
  for win, bar in pairs(saved_bars) do
    if vim.api.nvim_win_is_valid(win) then
      vim.wo[win].winbar = bar
    end
    saved_bars[win] = nil
  end
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  if recording and vim.bo[buf].buftype == "" and vim.api.nvim_win_get_config(win).relative == "" then
    saved_bars[win] = vim.wo[win].winbar
    local label = " RECORDING @" .. vim.fn.reg_recording() .. " "
    local width = vim.api.nvim_win_get_width(win)
    local left = math.max(0, math.floor((width - #label) / 2))
    vim.wo[win].winbar = "%#MacroRecording#" .. string.rep(" ", left) .. label .. string.rep(" ", math.max(0, width - left - #label))
  end
end

vim.api.nvim_create_autocmd("RecordingEnter", {
  group = group,
  callback = function()
    clear_marker()
    recording = true
    start_buffer = vim.api.nvim_get_current_buf()
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.api.nvim_buf_set_extmark(start_buffer, namespace, cursor[1] - 1, cursor[2], {
      virt_text = { { " ◀ Macro recording started here", "MacroRecordingStart" } },
      virt_text_pos = "eol",
      right_gravity = false,
    })
    update()
  end,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  group = group,
  callback = function()
    recording = false
    clear_marker()
    update()
  end,
})

vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "WinResized" }, { group = group, callback = update })
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
highlights()

return M
