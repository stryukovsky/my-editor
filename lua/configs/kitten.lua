-- Kitty remote control (`kitten @ …`).
--
-- Neovim no longer uses its own tabs as "project workspaces". A project is a
-- Kitty tab. This module is the only place we talk to Kitty.
--
-- How it reaches the running Kitty:
--   kitty.conf has `allow_remote_control socket-only` + `listen_on unix:/tmp/kitty-{kitty_pid}`.
--   Kitty then sets KITTY_LISTEN_ON in this process. `kitten @` uses that socket.
--   If you run Neovim outside Kitty, set M.socket to that unix: path yourself.
--
-- Commands we use:
--   kitten @ launch --type=tab [--cwd=…] [--tab-title=…]   -- new tab
--   kitten @ ls                                            -- JSON tree of OS windows → tabs → windows
--   kitten @ focus-tab --match id:N                        -- jump to tab by Kitty's id (not tab-bar index)
--
-- Tweak M.socket / M.argv / M.type below; everything else builds on those.

local notify = require "configs.notify"

local M = {}

--- `kitten @ --to SOCKET`. nil = KITTY_LISTEN_ON from the environment.
--- Example: "unix:/tmp/kitty-1234"
M.socket = nil

--- Program started in a launched tab. {} = Kitty's default shell.
--- Example: { "nvim" }
M.argv = {}

--- Default `--type=` for M.launch (`tab` | `window` | `os-window` | …).
M.type = "tab"

---@class KittenLaunchOpts
---@field type? string
---@field cwd? string
---@field tab_title? string
---@field title? string
---@field keep_focus? boolean
---@field socket? string
---@field argv? string[]

-- Build `kitten @ [--to SOCKET] <args>` so every call hits the same Kitty instance.
---@param args string[]
---@return string[]
function M.at(args)
  local cmd = { "kitten", "@" }
  local socket = M.socket or vim.env.KITTY_LISTEN_ON
  if socket and socket ~= "" then
    cmd[#cmd + 1] = "--to"
    cmd[#cmd + 1] = socket
  end
  for _, arg in ipairs(args) do
    cmd[#cmd + 1] = arg
  end
  return cmd
end

-- Run that command, wait, return stdout. Toast on failure unless `silent` (picker `ls`).
---@param args string[]
---@param opts? { silent?: boolean }
---@return string|nil, string|nil
function M.run(args, opts)
  opts = opts or {}
  local result = vim.system(M.at(args), { text = true }):wait()
  if result.code ~= 0 then
    local err = (result.stderr or ""):gsub("%s+$", "")
    if err == "" then
      err = "kitten @ " .. (args[1] or "command") .. " failed"
    end
    if not opts.silent then
      notify.send("Kitty", err, vim.log.levels.ERROR)
    end
    return nil, err
  end
  return result.stdout or ""
end

-- Assemble `kitten @ launch …` argv from opts (cwd, tab title, program). Does not execute.
---@param opts? KittenLaunchOpts
---@return string[]
function M.cmd(opts)
  opts = opts or {}
  local args = { "launch", "--type=" .. (opts.type or M.type) }
  if opts.cwd and opts.cwd ~= "" then
    args[#args + 1] = "--cwd=" .. opts.cwd
  end
  if opts.tab_title and opts.tab_title ~= "" then
    args[#args + 1] = "--tab-title=" .. opts.tab_title
  end
  if opts.title and opts.title ~= "" then
    args[#args + 1] = "--title=" .. opts.title
  end
  if opts.keep_focus then
    args[#args + 1] = "--keep-focus"
  end
  for _, arg in ipairs(opts.argv or M.argv) do
    args[#args + 1] = arg
  end
  local cmd = { "kitten", "@" }
  local socket = opts.socket or M.socket or vim.env.KITTY_LISTEN_ON
  if socket and socket ~= "" then
    cmd[#cmd + 1] = "--to"
    cmd[#cmd + 1] = socket
  end
  for _, arg in ipairs(args) do
    cmd[#cmd + 1] = arg
  end
  return cmd
end

-- Create a new Kitty tab/window. Used by <leader>tab and by opening a missing project.
---@param opts? KittenLaunchOpts
---@return boolean
function M.launch(opts)
  local result = vim.system(M.cmd(opts), { text = true }):wait()
  if result.code ~= 0 then
    local err = (result.stderr or ""):gsub("%s+$", "")
    if err == "" then
      err = "kitten @ launch failed"
    end
    notify.send("Kitty", err, vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Fetch the live window tree. nil if Kitty is not listening (outside Kitty, bad socket).
---@return table[]|nil
function M.ls()
  local stdout = M.run({ "ls" }, { silent = true })
  if not stdout or vim.trim(stdout) == "" then
    return nil
  end
  local ok, data = pcall(vim.json.decode, stdout)
  if not ok or type(data) ~= "table" then
    return nil
  end
  return data
end

---@class KittenTab
---@field id integer Kitty tab id (stable; not the 1-based tab-bar index)
---@field title string `--tab-title` we set, or Kitty's default window title
---@field cwd? string cwd of the focused/active window in that tab

-- Flatten ls() into { id, title, cwd } per tab so projects can match by name/path.
---@return KittenTab[]
function M.tabs()
  local tree = M.ls()
  if not tree then
    return {}
  end
  local tabs = {}
  for _, os_win in ipairs(tree) do
    for _, tab in ipairs(os_win.tabs or {}) do
      -- Prefer the focused window's cwd; otherwise last window that has one.
      local cwd
      for _, win in ipairs(tab.windows or {}) do
        if type(win.cwd) == "string" and win.cwd ~= "" then
          cwd = win.cwd
          if win.is_active or win.is_focused then
            break
          end
        end
      end
      tabs[#tabs + 1] = { id = tab.id, title = tab.title or "", cwd = cwd }
    end
  end
  return tabs
end

-- Focus an existing tab by Kitty id (from ls), not by 1-based position on the tab bar.
---@param id integer
---@return boolean
function M.focus_tab(id)
  local stdout = M.run { "focus-tab", "--match", "id:" .. tostring(id) }
  return stdout ~= nil
end

return M
