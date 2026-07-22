local M = {}

local cache = {}
local cache_order = {}
local MAX_CACHE = 10

local function hash_input(lines)
  local str = table.concat(lines, "\n")
  local h = 0
  for i = 1, #str do
    h = (h * 31 + string.byte(str, i)) % 2 ^ 31
  end
  return tostring(h)
end

local function open_buffer(out_lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "plantuml-preview"
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = true

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_set_current_buf(buf)
  vim.wo.wrap = false

  local ok = pcall(vim.api.nvim_buf_set_name, buf, "plantuml-preview")
  if not ok then
    vim.api.nvim_buf_set_name(buf, "plantuml-preview" .. math.random(9999))
  end
end

function M.visualize(lines)
  if not lines or #lines == 0 then
    vim.notify("No lines to visualize", vim.log.levels.ERROR)
    return
  end

  local key = hash_input(lines)
  if cache[key] then
    open_buffer(cache[key])
    return
  end

  local input = table.concat(lines, "\n") .. "\n"

  local result = vim
    .system({ "plantuml", "-utxt", "-p" }, {
      text = true,
      stdin = input,
    })
    :wait()

  if result.code ~= 0 then
    vim.notify("plantuml failed: " .. ((result.stderr or "exit code ") .. result.code), vim.log.levels.ERROR)
    return
  end

  local output = result.stdout
  if not output or #output == 0 then
    vim.notify("plantuml produced no output", vim.log.levels.WARN)
    return
  end

  local out_lines = vim.split(output, "\n", { plain = true })

  if #cache_order >= MAX_CACHE then
    local oldest = table.remove(cache_order, 1)
    cache[oldest] = nil
  end
  cache[key] = out_lines
  table.insert(cache_order, key)

  open_buffer(out_lines)
end

return M
