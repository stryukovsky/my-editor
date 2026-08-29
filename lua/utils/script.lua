local M = {}

local permission_chars = {
  { char = "r", bit = 256 },
  { char = "w", bit = 128 },
  { char = "x", bit = 64 },
  { char = "r", bit = 32 },
  { char = "w", bit = 16 },
  { char = "x", bit = 8 },
  { char = "r", bit = 4 },
  { char = "w", bit = 2 },
  { char = "x", bit = 1 },
}

---@param permissions integer
---@return string
local function mode_string(permissions)
  local chars = {}
  for index, permission in ipairs(permission_chars) do
    chars[index] = permissions % (permission.bit * 2) >= permission.bit and permission.char or "-"
  end
  return table.concat(chars)
end

---@param mode string
---@return integer|nil
---@return string|nil
local function parse_mode(mode)
  if #mode ~= #permission_chars then
    return nil, "Mode must contain exactly nine characters (for example rwxr-xr-x)"
  end

  local permissions = 0
  for index, permission in ipairs(permission_chars) do
    local char = mode:sub(index, index)
    if char == permission.char then
      permissions = permissions + permission.bit
    elseif char ~= "-" then
      return nil, ("Character %d must be %q or '-'"):format(index, permission.char)
    end
  end
  return permissions
end

---@param path string
---@return string|nil mode
---@return string|nil error
function M.mode_string(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil, "File does not exist"
  end
  return mode_string(stat.mode % 512)
end

---@param path string
---@param mode string
---@return boolean|nil success
---@return boolean|string changed_or_error
function M.set_mode(path, mode)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil, "File does not exist"
  end

  local permissions, err = parse_mode(mode)
  if not permissions then
    return nil, err
  end
  if stat.mode % 512 == permissions then
    return true, false
  end

  local ok, chmod_error = vim.uv.fs_chmod(path, permissions)
  if not ok then
    return nil, chmod_error or "Could not change permissions"
  end
  return true, true
end

--- Ensure a regular file has owner-execute permission.
---@param path string
---@return boolean|nil success
---@return boolean|string changed_or_error
-- TODO: lets just return string, if it is empty then success otherwise, error msg is not empty
function M.ensure_user_executable(path)
  local stat = vim.uv.fs_stat(path)
  if not stat then
    return nil, "File does not exist"
  end
  if stat.type ~= "file" then
    return nil, "Not a regular file"
  end

  local permissions = stat.mode % 512
  if permissions % 128 >= 64 then
    return true, false
  end

  local ok, err = vim.uv.fs_chmod(path, permissions + 64)
  if not ok then
    return nil, err or "Could not add owner-execute permission"
  end
  return true, true
end

return M
