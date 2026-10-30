local M = {}

-- A mode label avoids changing terminal or window colors.
function M.mode_label()
  local win = vim.g.statusline_winid
  local active = win == vim.api.nvim_get_current_win() and vim.api.nvim_get_mode().mode == "t"
  if active then
    return "%#TerminalInputBar# press <esc> to leave terminal, press <C-Esc> to send esc to process inside %= "
  end
  return "%#TerminalNormalBar# press 'i' to enter terminal %= "
end

local terminal_winbar = "%!v:lua.require'configs.terminal'.mode_label()"
vim.api.nvim_create_autocmd({ "ModeChanged", "BufWinEnter", "WinEnter", "TermOpen", "TermEnter", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("TerminalModeIndicator", { clear = true }),
  callback = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      -- Clean up shading left by the previous implementation when reloading.
      if vim.w[win].terminal_original_winhl ~= nil then
        vim.wo[win].winhighlight = vim.w[win].terminal_original_winhl
        vim.w[win].terminal_original_winhl = nil
      end
      local terminal = vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "terminal"
      if terminal then
        if vim.w[win].terminal_original_winbar == nil then
          vim.w[win].terminal_original_winbar = vim.wo[win].winbar == terminal_winbar and "" or vim.wo[win].winbar
        end
        vim.wo[win].winbar = terminal_winbar
      elseif vim.w[win].terminal_original_winbar ~= nil then
        if vim.wo[win].winbar == terminal_winbar or vim.wo[win].winbar == "" then
          vim.wo[win].winbar = vim.w[win].terminal_original_winbar
        end
        vim.w[win].terminal_original_winbar = nil
      elseif vim.wo[win].winbar == terminal_winbar then
        vim.wo[win].winbar = ""
      end
    end
    vim.cmd "redrawstatus"
  end,
})

-- Embedded terminals consume OSC requests instead of passing them to the host.
-- Forward notification protocols so Kitty/Ghostty can show desktop alerts.
vim.api.nvim_create_autocmd("TermRequest", {
  group = vim.api.nvim_create_augroup(
    "TerminalDesktopNotifications",
    { clear = true }
  ),
  callback = function(event)
    local data = event.data
    local sequence = data and data.sequence or vim.v.termrequest
    if not sequence then
      return
    end
    if
      sequence:match "^\027%]9;"
      or sequence:match "^\027%]99;"
      or sequence:match "^\027%]777;notify;"
    then
      vim.api.nvim_ui_send(sequence .. (data and data.terminator or "\027\\"))
    end
  end,
})

local taken_names = {}
local taken_icons = {}
---@type boolean|nil
local zsh_available

local function unique_name(base)
  if not taken_names[base] then
    taken_names[base] = true
    return base
  end
  local i = 1
  while true do
    local candidate = base .. " (" .. i .. ")"
    if not taken_names[candidate] then
      taken_names[candidate] = true
      return candidate
    end
    i = i + 1
  end
end

local function release_terminal_identity(buf)
  local name = vim.b[buf].terminal_unique_name
  if name then
    taken_names[name] = nil
    vim.b[buf].terminal_unique_name = nil
  end

  local icon = vim.b[buf].terminal_icon
  if icon then
    taken_icons[icon] = nil
    vim.b[buf].terminal_icon = nil
  end
end

local function set_terminal_name(buf, base, icon)
  release_terminal_identity(buf)
  local name = unique_name(base)
  vim.api.nvim_buf_set_name(buf, name)
  vim.b[buf].terminal_unique_name = name
  if icon then
    taken_icons[icon] = true
    vim.b[buf].terminal_icon = icon
  end
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("TerminalUniqueNames", { clear = true }),
  callback = function(event)
    release_terminal_identity(event.buf)
  end,
})

math.randomseed(vim.uv.hrtime())

local function random_icon()
  local icons = {
    "",
    "",
    "",
    "󱜿",
    "󱦡",
    "󰟻",
    "󰨶",
    "󱗫",
    "󰉀",
    "󱠂",
    "󱩡",
    "󱀆",
    "󰏖",
    "󱗃",
    "󰢗",
    "󱒕",
    "",
    "󰚆",
    "󰭥",
    "",
    "󰊘",
    "",
    "",
    "󱁏",
    "",
    "",
    "",
    "󰀸",
  }
  local available = {}
  for _, icon in ipairs(icons) do
    if not taken_icons[icon] then
      table.insert(available, icon)
    end
  end
  if #available == 0 then
    return nil
  end
  return available[math.random(#available)]
end

---@param buf integer
---@param base string
---@param icon? string
function M.set_name(buf, base, icon)
  set_terminal_name(buf, base, icon)
end

---@param name? string
function M.release_name(name)
  if name then
    taken_names[name] = nil
  end
end

--- Show and pin a terminal buffer using the shared terminal identity rules.
---@param buf integer
---@param name? string task name, or a random icon for an interactive shell
function M.show(buf, name)
  vim.bo[buf].buflisted = true
  vim.api.nvim_set_current_buf(buf)
  vim.cmd.BufferPin()
  local icon = not name and random_icon() or nil
  M.set_name(buf, "  " .. (name or icon or "") .. " ", icon)
end

--- Open a pinned Neovim terminal in the current window, like `<leader>tn`.
---@param cwd? string working directory for the new shell
---@return boolean
function M.open_new(cwd)
  if cwd and cwd ~= "" then
    local stat = vim.uv.fs_stat(cwd)
    if not stat or stat.type ~= "directory" then
      vim.notify("Cannot start terminal: not a directory", vim.log.levels.WARN)
      return false
    end
    vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  end
  if zsh_available == nil then
    zsh_available = vim.fn.executable "zsh" == 1
  end
  vim.cmd.terminal(zsh_available and "zsh" or "bash")
  M.show(vim.api.nvim_get_current_buf())
  return true
end

return M
