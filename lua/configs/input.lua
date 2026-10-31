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

-- `opts.virtual_text_mode`. Slash search is the only value for now.
local VIRTUAL_TEXT_SLASH_SEARCH = "slash_search"
local VIRT_NS = vim.api.nvim_create_namespace "input_float_virtual_text"

---`found: N` inline, so it stays beside the text in insert mode.
---@param buf integer
---@param line string
---@param count integer
---@param capped boolean
local function show_slash_count(buf, line, count, capped)
  local label = " found: " .. count .. (capped and "+" or "")
  vim.api.nvim_buf_set_extmark(buf, VIRT_NS, 0, #line, {
    id = 1,
    virt_text = { { label, "Comment" } },
    virt_text_pos = "inline",
    right_gravity = true,
  })
end

---@param buf integer
local function clear_slash_count(buf)
  pcall(vim.api.nvim_buf_del_extmark, buf, VIRT_NS, 1)
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

---Esc in insert leaves insert; Esc/q in normal cancel; CR submits.
---@param buf integer
---@param opts { submit: fun(), cancel: fun(), submit_modes?: string|string[] }
function M.bind_float_keys(buf, opts)
  pcall(vim.keymap.del, "i", "<Esc>", { buffer = buf })
  map("i", "<Esc>", function()
    vim.cmd "stopinsert"
  end, { buffer = buf, nowait = true })
  map("n", "<Esc>", opts.cancel, { buffer = buf, nowait = true })
  map("n", "q", opts.cancel, { buffer = buf, nowait = true })
  map(
    opts.submit_modes or { "i", "n" },
    "<CR>",
    opts.submit,
    { buffer = buf, nowait = true }
  )
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

---Float input. `opts.on_input(value)` runs on each edit, before confirm.
---`opts.filetype`: nonempty filetype opts into native completion and FileType hooks.
---Omitted/empty filetype keeps completion off. `opts.cwd` supplies Git context.
---@param opts { prompt?: string, default?: string, filetype?: string, cwd?: string, on_input?: function, virtual_text_mode?: string }
---@param on_confirm fun(value: string|nil)
---`opts.virtual_text_mode = "slash_search"`: `on_input` may return a match
---count (and `true` when that count is capped). The float draws `found: N`
---beside the text, including while insert mode is active.
function M.setup()
  vim.ui.input = function(opts, on_confirm)
    opts = opts or {}
    on_confirm = on_confirm or function() end
    -- Capture before opening the float / startinsert.
    local prev_mode = vim.api.nvim_get_mode().mode
    local prev_win = vim.api.nvim_get_current_win()
    local prev_view = vim.fn.winsaveview()
    local prompt = opts.prompt or "Input"
    local default = opts.default == nil and "" or tostring(opts.default)
    local filetype = opts.filetype or ""
    vim.validate("filetype", filetype, "string")
    local completion = filetype ~= ""
    local cwd = opts.cwd or vim.fn.getcwd()
    local max_width = math.max(1, vim.o.columns - 4)
    local preferred = math.floor(vim.o.columns * 0.6)
    local width =
      math.min(max_width, math.max(preferred, display_width(default) + 8, 72))
    local height = 1
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)
    local buffer = vim.api.nvim_create_buf(false, true)
    local completed = false
    local mode_autocmd ---@type integer?

    vim.bo[buffer].bufhidden = "wipe"
    vim.bo[buffer].buftype = "nofile"
    vim.bo[buffer].swapfile = false
    -- Native completion respects this flag on InsertEnter.
    vim.b[buffer].input_completion = completion
    vim.b[buffer].completion = completion
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
      if
        vim.api.nvim_win_is_valid(prev_win)
        and vim.api.nvim_get_current_win() ~= prev_win
      then
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
        local function restore_view()
          if not vim.api.nvim_win_is_valid(prev_win) then
            return
          end
          pcall(vim.api.nvim_win_call, prev_win, function()
            vim.fn.winrestview(prev_view)
          end)
        end
        -- stopinsert shifts the cursor one column later, on InsertLeave.
        -- Restore the view there, then confirm. A pending InsertLeave must not
        -- run after on_confirm, or it puts the cursor back and drops the jump.
        local function deliver()
          restore_view()
          on_confirm(value)
        end
        if vim.fn.mode():find "^[iR]" and not prev_mode:find "^[iR]" then
          vim.api.nvim_create_autocmd("InsertLeave", {
            once = true,
            callback = function()
              vim.schedule(deliver)
            end,
          })
          restore_mode(prev_mode)
        else
          restore_mode(prev_mode)
          vim.schedule(deliver)
        end
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

    M.bind_float_keys(buffer, {
      submit = function()
        finish(vim.api.nvim_get_current_line())
      end,
      cancel = cancel,
      submit_modes = completion and "n" or { "i", "n" },
    })

    if completion then
      map({ "i", "s" }, "<CR>", function()
        if
          vim.fn.pumvisible() == 1
          and vim.fn.complete_info({ "selected" }).selected >= 0
        then
          return "<C-y>"
        end
        vim.schedule(function()
          if not completed and vim.api.nvim_win_is_valid(window) then
            finish(vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] or "")
          end
        end)
        return vim.fn.pumvisible() == 1 and "<C-e>" or ""
      end, {
        buffer = buffer,
        expr = true,
        desc = "Accept completion or submit input",
      })
      for key, direction in pairs { ["<Tab>"] = 1, ["<S-Tab>"] = -1 } do
        map({ "i", "s" }, key, function()
          if vim.snippet.active { direction = direction } then
            vim.schedule(function()
              vim.snippet.jump(direction)
            end)
            return ""
          end
          return key
        end, {
          buffer = buffer,
          expr = true,
          desc = "Jump input snippet placeholder",
        })
      end
      vim.bo[buffer].filetype = filetype
      -- Filetype formatting must not wrap a one-line input into hidden lines.
      vim.bo[buffer].textwidth = 0
      vim.bo[buffer].formatoptions = ""
      if filetype == "gitcommit" then
        require("configs.input_completion").setup(buffer, cwd)
      end
    end

    local virtual_text_mode = opts.virtual_text_mode
    if
      virtual_text_mode == VIRTUAL_TEXT_SLASH_SEARCH
      and vim.api.nvim_win_is_valid(window)
    then
      -- Room to the right of the cursor so `found: N` is not scrolled off in insert.
      vim.wo[window].wrap = false
      vim.wo[window].sidescrolloff = 16
    end

    if type(opts.on_input) == "function" then
      vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
        buffer = buffer,
        callback = function()
          if completed then
            return
          end
          local line = vim.api.nvim_get_current_line()
          local ok, count, capped = pcall(opts.on_input, line)
          if
            virtual_text_mode ~= VIRTUAL_TEXT_SLASH_SEARCH
            or not vim.api.nvim_buf_is_valid(buffer)
          then
            return
          end
          if ok and type(count) == "number" then
            show_slash_count(buffer, line, count, capped == true)
          else
            clear_slash_count(buffer)
          end
        end,
      })
    end

    vim.cmd "startinsert"
    -- startinsert is async w.r.t. mode; refresh once insert is active.
    vim.schedule(refresh_title)
  end

  vim.input = vim.ui.input
end

return M
