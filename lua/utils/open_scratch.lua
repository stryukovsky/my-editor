---@param name string
---@param skip integer
---@return boolean
local function name_in_use(name, skip)
  local abs = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= skip and vim.api.nvim_buf_is_valid(buf) then
      local existing = vim.api.nvim_buf_get_name(buf)
      if existing ~= "" and vim.fs.normalize(existing) == abs then
        return true
      end
    end
  end
  return false
end

---@param name string
---@param buf integer
---@return string
local function unique_name(name, buf)
  if not name_in_use(name, buf) then
    return name
  end
  local i = 2
  while name_in_use(name .. "-" .. i, buf) do
    i = i + 1
  end
  return name .. "-" .. i
end

---@param lines string[]|nil
---@return string[]
local function normalize_lines(lines)
  local normalized = {}
  for _, line in ipairs(lines or {}) do
    line = tostring(line):gsub("\r\n", "\n")
    vim.list_extend(normalized, vim.split(line, "\n", { plain = true, trimempty = false }))
  end
  return normalized
end

---@class utils.OpenScratchOpts
---@field name string
---@field lines string[]
---@field filetype? string
---@field listed? boolean
---@field bufhidden? string
---@field buftype? string
---@field modifiable? boolean
---@field show? boolean

--- Open an unlisted scratch buffer, name it uniquely, and optionally show it.
---@param opts utils.OpenScratchOpts
---@return integer
return function(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = opts.bufhidden or "wipe"
  vim.bo[buf].buflisted = opts.listed ~= false
  if opts.buftype then
    vim.bo[buf].buftype = opts.buftype
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, normalize_lines(opts.lines))
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = opts.modifiable == true

  pcall(vim.api.nvim_buf_set_name, buf, unique_name(opts.name, buf))

  if opts.filetype then
    vim.bo[buf].filetype = opts.filetype
  end

  if opts.show ~= false then
    vim.api.nvim_set_current_buf(buf)
  end

  return buf
end
