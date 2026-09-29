local notify = require "configs.notify"

local M = {}

local CANDIDATES = {
  ".venv/bin/python",
  "venv/bin/python",
}

---@param root? string
---@return string|nil
function M.find(root)
  root = root or vim.fn.getcwd()
  if root == "" or vim.fn.isdirectory(root) == 0 then
    return nil
  end
  for _, rel in ipairs(CANDIDATES) do
    local py = vim.fs.normalize(root .. "/" .. rel)
    if vim.fn.executable(py) == 1 then
      return py
    end
  end
  return nil
end

---@param python string
function M.apply(python)
  require("dap-python").setup(python, { console = nil, include_configs = false })
  local dap = require "dap"
  dap.configurations.python = {
    {
      type = "python",
      request = "launch",
      name = "Run Command",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = function()
        return vim.fn.input "Command:"
      end,
    },
    {
      type = "python",
      request = "launch",
      name = "Run file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
  }
  vim.fn.system { python, "-m", "pip", "install", "debugpy" }
  for _, name in ipairs { "basedpyright", "pyright" } do
    pcall(vim.lsp.config, name, {
      settings = {
        python = { pythonPath = python },
      },
    })
    for _, client in ipairs(vim.lsp.get_clients { name = name }) do
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
        python = { pythonPath = python },
      })
      pcall(function()
        client:notify("workspace/didChangeConfiguration", { settings = client.settings })
      end)
    end
  end
end

local function root()
  local ok, projects = pcall(require, "configs.projects")
  if ok then
    return projects.tab_project() or projects.current_root() or vim.fn.getcwd()
  end
  return vim.fn.getcwd()
end

---@param python string
local function use(python)
  python = vim.fs.normalize(vim.fn.expand(python))
  if vim.fn.executable(python) ~= 1 then
    notify.send("Python", "Not executable: " .. python, vim.log.levels.ERROR)
    return
  end
  M.apply(python)
  notify.send("Python", "DAP adapter: " .. python, vim.log.levels.INFO)
end

function M.setup()
  local found = M.find(root())
  if found then
    use(found)
    return
  end
  vim.ui.input({
    prompt = "Python executable",
    default = "python",
  }, function(value)
    if not value or vim.trim(value) == "" then
      return
    end
    use(value)
  end)
end

return M
