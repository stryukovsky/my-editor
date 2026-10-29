local M = {}
local uv = vim.uv or vim.loop

local function state_path()
  return vim.fn.stdpath "data" .. "/neotree-clipboard.json"
end

local function valid_paths(paths)
  if type(paths) ~= "table" or not vim.islist(paths) then
    return false
  end
  for _, path in ipairs(paths) do
    if
      type(path) ~= "string"
      or path == ""
      or path:find("\0", 1, true)
      or not vim.startswith(path, "/")
    then
      return false
    end
  end
  return true
end

-- Optional paths allow verification without touching the user's clipboard.
function M.write(paths, path)
  if not valid_paths(paths) or #paths == 0 then
    return nil, "Invalid or empty copy selection"
  end
  path = path or state_path()
  local ok, err = pcall(vim.fn.mkdir, vim.fn.fnamemodify(path, ":h"), "p")
  if not ok then
    return nil, err
  end
  local fd, temporary = uv.fs_mkstemp(path .. ".XXXXXX")
  if not fd then
    return nil, temporary
  end
  local content = vim.json.encode { version = 1, paths = paths }
  local written, write_err = uv.fs_write(fd, content, 0)
  local closed, close_err = uv.fs_close(fd)
  if written ~= #content or not closed then
    uv.fs_unlink(temporary)
    return nil, write_err or close_err or "Incomplete clipboard write"
  end
  local renamed, rename_err = uv.fs_rename(temporary, path)
  if not renamed then
    uv.fs_unlink(temporary)
    return nil, rename_err
  end
  return true
end

function M.read(path)
  path = path or state_path()
  local fd, err, code = uv.fs_open(path, "r", 0)
  if not fd then
    if code == "ENOENT" then
      return {}
    end
    return nil, "Cannot read clipboard: " .. tostring(err)
  end
  local stat, stat_err = uv.fs_fstat(fd)
  local content, read_err
  if stat and stat.type == "file" then
    content, read_err = uv.fs_read(fd, stat.size, 0)
  end
  uv.fs_close(fd)
  if not content then
    return nil,
      "Cannot read clipboard: " .. tostring(
        read_err or stat_err or "Not a regular file"
      )
  end
  if content == "" then
    return {}
  end
  local ok, value = pcall(vim.json.decode, content)
  if not ok or type(value) ~= "table" then
    return nil, "Malformed clipboard state"
  end
  if value.version ~= 1 then
    return nil, "Unsupported clipboard version"
  end
  if not valid_paths(value.paths) then
    return nil, "Malformed clipboard paths"
  end
  return value.paths
end

local function notify(message, level)
  require("configs.notify").send(
    "Neo-tree",
    message,
    level or vim.log.levels.WARN
  )
end

function M.copy_visual(state, nodes)
  local paths, clipboard = {}, {}
  for _, node in ipairs(nodes or {}) do
    if
      node.type == "file"
      or node.type == "directory"
      or node.type == "link"
    then
      local path = node.path or node:get_id()
      if type(path) == "string" and path ~= "" then
        path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")
        if path ~= "" and not clipboard[path] then
          paths[#paths + 1] = path
          clipboard[path] = { action = "copy", node = node }
        end
      end
    end
  end
  if #paths == 0 then
    return
  end
  local ok, err = M.write(paths)
  if not ok then
    notify(
      "Cannot save shared clipboard: " .. tostring(err),
      vim.log.levels.ERROR
    )
    return
  end
  state.clipboard = clipboard
  local events = require "neo-tree.events"
  events.fire_event(events.NEO_TREE_CLIPBOARD_CHANGED, { state = state })
  require("neo-tree.ui.renderer").redraw(state)
end

function M.copy(state)
  local node = state.tree:get_node()
  M.copy_visual(state, node and { node } or {})
end

function M.paste(state)
  local native = require "neo-tree.sources.filesystem.commands"
  local cuts = {}
  for id, item in pairs(state.clipboard or {}) do
    if item.action == "cut" then
      cuts[id] = item
    end
  end
  if next(cuts) then
    state.clipboard = cuts
    native.paste_from_clipboard(state)
    return
  end
  local paths, err = M.read()
  if not paths then
    notify(err, vim.log.levels.ERROR)
    return
  end
  if #paths == 0 then
    notify "Nothing to paste"
    return
  end
  local clipboard = {}
  for _, path in ipairs(paths) do
    local stat = uv.fs_lstat(path)
    if stat then
      clipboard[path] = {
        action = "copy",
        node = {
          id = path,
          path = path,
          name = vim.fn.fnamemodify(path, ":t"),
          type = stat.type,
        },
      }
    else
      notify("Source unavailable: " .. path)
    end
  end
  if not next(clipboard) then
    return
  end
  -- Native paste snapshots and clears this table synchronously. Its async copy
  -- callbacks never restore it, so a later user copy/cut remains untouched.
  state.clipboard = clipboard
  native.paste_from_clipboard(state)
end

return M
