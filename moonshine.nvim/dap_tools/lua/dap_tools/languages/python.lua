local M = {}

local function executable(environment)
  for _, relative in ipairs {
    "bin/python",
    "bin/python3",
    "Scripts/python.exe",
    "python.exe",
  } do
    local path = vim.fs.joinpath(environment, relative)
    if vim.fn.executable(path) == 1 then
      return path
    end
  end
end

local function project_python(root)
  for _, name in ipairs {
    ".venv",
    "venv",
    "env",
    ".env",
    "virtualenv",
    ".virtualenv",
  } do
    local path = executable(vim.fs.joinpath(root, name))
    if path then
      return path
    end
  end
  -- Also recognize custom-named virtualenvs, without recursively scanning projects.
  local environments = {}
  for name, kind in vim.fs.dir(root) do
    if
      kind == "directory"
      and vim.fn.filereadable(vim.fs.joinpath(root, name, "pyvenv.cfg")) == 1
    then
      environments[#environments + 1] = name
    end
  end
  table.sort(environments)
  for _, name in ipairs(environments) do
    local path = executable(vim.fs.joinpath(root, name))
    if path then
      return path
    end
  end
end

function M.resolve(root)
  local cwd = vim.fn.getcwd()
  local path = project_python(cwd)
  if path then
    return path
  end
  root = root or require("dap_tools.project").root()
  if root ~= cwd and vim.fn.isdirectory(root) == 1 then
    path = project_python(root)
    if path then
      return path
    end
  end
  for _, environment in ipairs { "VIRTUAL_ENV", "CONDA_PREFIX" } do
    local directory = vim.env[environment]
    if directory and directory ~= "" then
      path = executable(directory)
      if path then
        return path
      end
    end
  end
  for _, command in ipairs { "python3", "python" } do
    path = vim.fn.exepath(command)
    if path ~= "" then
      return path
    end
  end
  error "No Python executable found in the project environments or PATH"
end

function M.activate(root)
  local python = require "dap-python"
  python.resolve_python = function()
    return M.resolve(root)
  end
  python.setup(M.resolve(root), { include_configs = false })
end

return M
