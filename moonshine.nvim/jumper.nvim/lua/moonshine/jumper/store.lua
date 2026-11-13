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

function M.new(path)
  local state = { path = path or (vim.fn.stdpath("data") .. "/jumper-marks.json"), marks = {}, writable = true }
  local uv = vim.uv

  function state:load()
    local file = io.open(self.path, "rb")
    if not file then
      if uv.fs_stat(self.path) then
        self.writable = false
        return false, "Cannot read jumper mark store: " .. self.path
      end
      return true
    end
    local contents = file:read("*a")
    file:close()
    local ok, decoded = pcall(vim.json.decode, contents)
    if not ok or type(decoded) ~= "table" or decoded.version ~= 1 or type(decoded.marks) ~= "table" then
      self.writable = false
      return false, "Invalid jumper mark store (left untouched): " .. self.path
    end
    for name, entry in pairs(decoded.marks) do
      if not valid_name(name) or not valid_position(entry) then
        self.writable = false
        return false, "Invalid jumper mark store (left untouched): " .. self.path
      end
    end
    self.marks = decoded.marks
    return true
  end

  function state:save()
    if not self.writable then
      return false, "Jumper mark store is read-only: " .. self.path
    end
    vim.fn.mkdir(vim.fn.fnamemodify(self.path, ":h"), "p")
    local tmp = self.path .. "." .. uv.os_getpid() .. ".tmp"
    local fd, err = uv.fs_open(tmp, "w", 384)
    if not fd then
      return false, err
    end
    local data = vim.json.encode { version = 1, marks = self.marks }
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
    return true
  end

  function state:set(name, entry)
    if not valid_name(name) or not valid_position(entry) then
      return false, "Invalid jumper mark"
    end
    if not self.writable then
      return false, "Jumper mark store is read-only"
    end
    self.marks[name] = { path = entry.path, row = entry.row, col = entry.col }
    return self:save()
  end

  function state:delete(name)
    if not valid_name(name) then
      return false, "Expected a lowercase mark name (a-z)"
    end
    if not self.writable then
      return false, "Jumper mark store is read-only"
    end
    self.marks[name] = nil
    return self:save()
  end

  return state
end

return M
