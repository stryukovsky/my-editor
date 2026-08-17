local M = {}
local map = require "mappings.map"

local MODE_TO_LUALINE = {
  n = "normal",
  i = "insert",
  v = "visual",
  V = "visual",
  ["\22"] = "visual",
  s = "visual",
  S = "visual",
  ["\19"] = "visual",
  r = "replace",
  R = "replace",
  c = "command",
  t = "terminal",
}

local MODE_LABELS = {
  n = "NORMAL",
  i = "INSERT",
  v = "VISUAL",
  V = "V-LINE",
  ["\22"] = "V-BLOCK",
  s = "SELECT",
  S = "S-LINE",
  ["\19"] = "S-BLOCK",
  r = "REPLACE",
  R = "REPLACE",
  c = "COMMAND",
  t = "TERMINAL",
}

---@param text string
---@return integer
local function display_width(text)
  return vim.fn.strdisplaywidth(text)
end

---Sync InputFloatMode from lualine mode colors (same source as highlight.lua CursorLineNr).
local function sync_mode_hl()
  local mode_name = MODE_TO_LUALINE[vim.fn.mode()] or "normal"
  local hl_data = vim.api.nvim_get_hl(0, { name = "lualine_a_" .. mode_name })
  if hl_data and hl_data.bg then
    vim.api.nvim_set_hl(0, "InputFloatMode", {
      bg = hl_data.bg,
      fg = hl_data.fg or "NONE",
      bold = true,
    })
  else
    vim.api.nvim_set_hl(0, "InputFloatMode", { link = "Title", bold = true })
  end
end

---@param prompt string
---@return [string, string][]
local function mode_title(prompt)
  sync_mode_hl()
  local label = MODE_LABELS[vim.fn.mode()] or vim.fn.mode():upper()
  return {
    { " " .. label .. " ", "InputFloatMode" },
    { " " .. prompt .. " ", "FloatTitle" },
  }
end

---Restore editor mode captured before the float opened.
---@param mode string from nvim_get_mode().mode
local function restore_mode(mode)
  if mode:find "^[i]" then
    vim.cmd "startinsert"
  elseif mode:sub(1, 1) == "R" then
    vim.cmd "startreplace"
  elseif mode:find "^[vV\22]" then
    pcall(vim.cmd, "normal! gv")
  else
    -- normal / operator-pending / etc.
    if vim.fn.mode():find "^[iR]" then
      vim.cmd "stopinsert"
    end
  end
end

function M.setup()
  vim.ui.input = function(opts, on_confirm)
    opts = opts or {}
    on_confirm = on_confirm or function() end
    -- Capture before opening the float / startinsert.
    local prev_mode = vim.api.nvim_get_mode().mode
    local prev_win = vim.api.nvim_get_current_win()
    local prompt = opts.prompt or "Input"
    local default = opts.default == nil and "" or tostring(opts.default)
    local max_width = math.max(1, vim.o.columns - 4)
    local preferred = math.floor(vim.o.columns * 0.6)
    local width = math.min(max_width, math.max(preferred, display_width(default) + 8, 72))
    local height = 1
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local buffer = vim.api.nvim_create_buf(false, true)
    local completed = false
    local mode_autocmd ---@type integer?

    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].swapfile = false
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { default })

    local window = vim.api.nvim_open_win(buffer, true, {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
      title = mode_title(prompt),
      title_pos = "center",
      zindex = 60,
    })

    local function refresh_title()
      if not vim.api.nvim_win_is_valid(window) then
        return
      end
      vim.api.nvim_win_set_config(window, {
        title = mode_title(prompt),
        title_pos = "center",
      })
    end

    mode_autocmd = vim.api.nvim_create_autocmd("ModeChanged", {
      callback = refresh_title,
    })

    local function restore_prev_win()
      if vim.api.nvim_win_is_valid(prev_win) and vim.api.nvim_get_current_win() ~= prev_win then
        pcall(vim.api.nvim_set_current_win, prev_win)
      end
    end

    local function finish(value)
      if completed then
        return
      end
      completed = true

      if mode_autocmd then
        pcall(vim.api.nvim_del_autocmd, mode_autocmd)
        mode_autocmd = nil
      end

      if vim.api.nvim_win_is_valid(window) then
        vim.api.nvim_win_close(window, true)
      end
      restore_prev_win()

      vim.schedule(function()
        restore_prev_win()
        restore_mode(prev_mode)
        on_confirm(value)
      end)
    end

    local cancel = function()
      finish(nil)
    end

    -- Leaving the float (click away, :wincmd, etc.) cancels input.
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
      buffer = buffer,
      callback = cancel,
    })

    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(window),
      once = true,
      callback = cancel,
    })

    map({ "i", "n" }, "<CR>", function()
      finish(vim.api.nvim_get_current_line())
    end, { buffer = buffer, nowait = true })
    map("n", "q", cancel, { buffer = buffer, nowait = true })
    map("n", "<Esc>", cancel, { buffer = buffer, nowait = true })

    vim.cmd "startinsert"
    -- startinsert is async w.r.t. mode; refresh once insert is active.
    vim.schedule(refresh_title)
  end

  vim.input = vim.ui.input
end

return M
