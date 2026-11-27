local M = {}

local function valid_name(name)
  return type(name) == "string" and name:match("^[a-z]$") ~= nil
end

local function valid_position(entry)
  return type(entry) == "table"
    and type(entry.path) == "string"
    and entry.path:sub(1, 1) == "/"
    and type(entry.row) == "number"
    and entry.row >= 1
    and entry.row % 1 == 0
    and type(entry.col) == "number"
    and entry.col >= 0
    and entry.col % 1 == 0
end

function M.new(path, legacy_path)
  local state = {
    path = path or (vim.fn.stdpath("data") .. "/jumper-marks-scoped.json"),
    legacy_path = legacy_path or (not path and vim.fn.stdpath("data") .. "/jumper-marks.json" or nil),
    marks = {},
    workspaces = {},
    legacy = {},
    cwd = nil,
    writable = true,
    needs_backup = false,
  }
  local uv = vim.uv

  local function valid_marks(marks, allow_deleted)
    if type(marks) ~= "table" then
      return false
    end
    for name, entry in pairs(marks) do
      if not valid_name(name) or (not valid_position(entry) and not (allow_deleted and entry == false)) then
        return false
      end
    end
    return true
  end

  local function under_cwd(file, cwd)
    return cwd == "/" or file == cwd or file:sub(1, #cwd + 1) == cwd .. "/"
  end

  local function read_legacy(file_path)
    local file = io.open(file_path, "rb")
    if not file then
      return nil, uv.fs_stat(file_path) and ("Cannot read jumper mark store: " .. file_path) or nil
    end
    local contents = file:read("*a")
    file:close()
    local ok, decoded = pcall(vim.json.decode, contents)
    if not ok or type(decoded) ~= "table" or decoded.version ~= 1 or not valid_marks(decoded.marks) then
      return nil, "Invalid jumper mark store (left untouched): " .. file_path
    end
    return decoded.marks
  end

  function state:select(cwd)
    self.cwd = vim.fs.normalize(cwd)
    local scoped = self.workspaces[self.cwd] or {}
    local marks = {}
    for name, entry in pairs(self.legacy) do
      if under_cwd(entry.path, self.cwd) and scoped[name] == nil then
        marks[name] = entry
      end
    end
    for name, entry in pairs(scoped) do
      if entry ~= false then
        marks[name] = entry
      end
    end
    self.marks = marks
  end

  function state:load()
    local file = io.open(self.path, "rb")
    if not file then
      if uv.fs_stat(self.path) then
        self.writable = false
        return false, "Cannot read jumper mark store: " .. self.path
      end
      if self.legacy_path then
        local marks, err = read_legacy(self.legacy_path)
        if err then
          self.writable = false
          return false, err
        end
        self.legacy = marks or {}
        self:select(self.cwd)
      end
      return true
    end
    local contents = file:read("*a")
    file:close()
    local ok, decoded = pcall(vim.json.decode, contents)
    if not ok or type(decoded) ~= "table" then
      self.writable = false
      return false, "Invalid jumper mark store (left untouched): " .. self.path
    end
    if decoded.version == 1 and valid_marks(decoded.marks) then
      self.legacy = decoded.marks
      self.needs_backup = true
    elseif decoded.version == 2 and valid_marks(decoded.legacy) and type(decoded.workspaces) == "table" then
      for cwd, marks in pairs(decoded.workspaces) do
        if type(cwd) ~= "string" or cwd:sub(1, 1) ~= "/" or not valid_marks(marks, true) then
          self.writable = false
          return false, "Invalid jumper mark store (left untouched): " .. self.path
        end
      end
      self.legacy = decoded.legacy
      self.workspaces = decoded.workspaces
    else
      self.writable = false
      return false, "Invalid jumper mark store (left untouched): " .. self.path
    end
    if self.cwd then
      self:select(self.cwd)
    end
    if self.legacy_path then
      local marks, err = read_legacy(self.legacy_path)
      if err then
        self.writable = false
        return false, err
      end
      if marks then
        self.legacy = marks
        self:select(self.cwd)
      end
    end
    return true
  end

  function state:save()
    if not self.writable then
      return false, "Jumper mark store is read-only: " .. self.path
    end
    vim.fn.mkdir(vim.fn.fnamemodify(self.path, ":h"), "p")
    if self.needs_backup then
      local backup = self.path .. ".v1.bak"
      if not uv.fs_stat(backup) then
        local copied, copy_err = uv.fs_copyfile(self.path, backup, { excl = true })
        if not copied then
          return false, "Cannot preserve legacy jumper marks: " .. tostring(copy_err)
        end
      end
    end
    local tmp = self.path .. "." .. uv.os_getpid() .. ".tmp"
    local fd, err = uv.fs_open(tmp, "w", 384)
    if not fd then
      return false, err
    end
    local data = vim.json.encode { version = 2, workspaces = self.workspaces, legacy = self.legacy }
    local written, write_err = uv.fs_write(fd, data, 0)
    local closed, close_err = uv.fs_close(fd)
    if not written or written ~= #data or not closed then
      uv.fs_unlink(tmp)
      return false, write_err or close_err or "Incomplete jumper mark write"
    end
    local renamed, rename_err = uv.fs_rename(tmp, self.path)
    if not renamed then
      uv.fs_unlink(tmp)
      return false, rename_err
    end
    self.needs_backup = false
    return true
  end

  function state:set(name, entry)
    if not valid_name(name) or not valid_position(entry) then
      return false, "Invalid jumper mark"
    end
    if not self.writable then
      return false, "Jumper mark store is read-only"
    end
    if not self.cwd then
      return false, "Jumper cwd is not selected"
    end
    self.workspaces[self.cwd] = self.workspaces[self.cwd] or {}
    local saved = { path = entry.path, row = entry.row, col = entry.col }
    self.workspaces[self.cwd][name] = saved
    self.marks[name] = saved
    return self:save()
  end

  function state:delete(name)
    if not valid_name(name) then
      return false, "Expected a lowercase mark name (a-z)"
    end
    if not self.writable then
      return false, "Jumper mark store is read-only"
    end
    if not self.cwd then
      return false, "Jumper cwd is not selected"
    end
    self.workspaces[self.cwd] = self.workspaces[self.cwd] or {}
    self.workspaces[self.cwd][name] = false -- Hide a legacy mark only in this cwd.
    self.marks[name] = nil
    return self:save()
  end

  state:select(vim.fn.getcwd())
  return state
end

return M
