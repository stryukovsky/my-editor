local M = {}

local taken_names = {}

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

local function set_terminal_name(buf, base)
  local name = unique_name(base)
  vim.api.nvim_buf_set_name(buf, name)
  vim.b[buf].terminal_unique_name = name
end

vim.api.nvim_create_autocmd("BufWipeout", {
  group = vim.api.nvim_create_augroup("TerminalUniqueNames", { clear = true }),
  callback = function(event)
    local name = vim.b[event.buf].terminal_unique_name
    if name then
      taken_names[name] = nil
    end
  end,
})

local function random_char()
  math.randomseed(os.time())

  local chars = {
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
  return chars[math.random(#chars)]
end

---@param buf integer
---@param base string
function M.set_name(buf, base)
  set_terminal_name(buf, base)
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
  vim.cmd.terminal()
  vim.cmd.BufferPin()
  M.set_name(0, "  " .. random_char() .. " ")
  return true
end

return M
