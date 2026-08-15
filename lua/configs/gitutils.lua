local M = {}

---@param args string[]
---@param cwd? string
---@param opts? { ok_codes?: table<integer, boolean> }
---@return string|nil stdout
---@return string|nil err
function M.run(args, cwd, opts)
  cwd = cwd or vim.fn.getcwd()
  opts = opts or {}
  local ok_codes = opts.ok_codes or { [0] = true }
  local cmd = { "git", "-C", cwd }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { text = true }):wait()
  if not ok_codes[result.code] then
    local err = vim.trim((result.stderr or "") ~= "" and result.stderr or ("git exited " .. result.code))
    return nil, err
  end
  return result.stdout or "", nil
end

---`git diff` may exit 1 when there are changes (`--exit-code` / some configs).
---@param args string[]
---@param cwd? string
---@return string|nil stdout
---@return string|nil err
function M.diff(args, cwd)
  return M.run(args, cwd, { ok_codes = { [0] = true, [1] = true } })
end

---@param dir? string
---@return string|nil root
---@return string|nil err
function M.root(dir)
  dir = dir or vim.fn.getcwd()
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  local out, err = M.run({ "rev-parse", "--show-toplevel" }, dir)
  if not out then
    return nil, err
  end
  return vim.fs.normalize(vim.trim(out)), nil
end

---@param path string
---@param cwd? string
---@return string
function M.relpath(path, cwd)
  local abs = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  local root = select(1, M.root(cwd or vim.fn.fnamemodify(abs, ":h")))
  if root then
    if abs == root then
      return "."
    end
    local prefix = root .. "/"
    if abs:sub(1, #prefix) == prefix then
      return abs:sub(#prefix + 1)
    end
  end
  return vim.fn.fnamemodify(path, ":t")
end

---@class gitutils.JobOpts
---@field args string[]
---@field cwd string
---@field on_exit fun(code: integer, stderr: string)

---@param opts gitutils.JobOpts
function M.job(opts)
  local cmd = { "git", "-C", opts.cwd }
  vim.list_extend(cmd, opts.args)
  local stderr = {}
  local id = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      local output = table.concat(data, "\n")
      if output ~= "" then
        stderr[#stderr + 1] = output
      end
    end,
    on_exit = function(_, code)
      opts.on_exit(code, table.concat(stderr, "\n"))
    end,
  })
  if id <= 0 then
    opts.on_exit(-1, "failed to start git")
  end
end

return M
