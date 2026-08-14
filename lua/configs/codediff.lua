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

---Apply the global wrap preference to every real window in the CodeDiff tab.
---@param enabled? boolean
function M.apply_wrap(enabled)
  if enabled == nil then
    enabled = vim.g.wrap ~= false
  end
  if not is_codediff_tab() then
    return
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_real_win(win) then
      set_win_wrap(win, enabled)
    end
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
  -- apply_codediff_bg()
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
    end
  end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    -- apply_codediff_bg()
    if is_codediff_tab() then
      M.apply_wrap()
    end
  end,
})

return M
