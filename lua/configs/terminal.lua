local M = {}

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
  vim.cmd.BufferPin()
  local icon = random_icon()
  M.set_name(0, icon and ("  " .. icon .. " ") or "  ", icon)
  return true
end

return M
