local M = {}

local function directory_for_todotxt()
  local home = vim.env.HOME
  local work_dir = home .. "/Work/my-vault/"

  if vim.fn.isdirectory(work_dir) == 1 then
    return work_dir
  else
    return home .. "/Documents/"
  end
end

function M.paths()
  local dir = directory_for_todotxt()
  return {
    todotxt = dir .. "todo.todotxt",
    donetxt = dir .. "done.todotxt",
  }
end

function M.enabled()
  return vim.uv.fs_stat(M.paths().todotxt) ~= nil
end

return M
