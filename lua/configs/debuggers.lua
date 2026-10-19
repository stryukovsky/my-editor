local dap = require "dap"

local function inputCommand()
  return vim.fn.input "Command:"
end

local function inputExecutable()
  return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
end

-- js-debug. `node` is the current launch.json type; `pwa-node` is the old name for the same server.
local js_debug = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "js-debug-adapter",
    args = { "${port}" },
  },
}
dap.adapters["pwa-node"] = js_debug
dap.adapters.node = js_debug

dap.adapters.codelldb = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "codelldb",
    args = { "--port", "${port}" },
  },
}

-- javascript
dap.configurations.javascript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    cwd = "${workspaceFolder}",
    skipFiles = { "${workspaceFolder}/node_modules/**" },
  },
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch command",
    program = "${file}",
    cwd = "${workspaceFolder}",
    runtimeExecutable = inputCommand,
    skipFiles = { "${workspaceFolder}/node_modules/**" },
  },
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach",
    processId = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}",
    skipFiles = { "${workspaceFolder}/node_modules/**" },
  },
}

-- typescript
dap.configurations.typescript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    cwd = "${workspaceFolder}",
    runtimeExecutable = "ts-node",
    -- sourceMaps = true,
    -- resolve source maps in nested locations while ignoring node_modules
    -- resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
    -- we don't want to debug code inside node_modules, so skip it!
    skipFiles = { "${workspaceFolder}/node_modules/**" },
  },
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch NPM script",
    cwd = "${workspaceFolder}",
    runtimeExecutable = "npm",
    runtimeArgs = { "run", inputCommand },
    skipFiles = { "${workspaceFolder}/node_modules/**" },
  },
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach",
    processId = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}",
    skipFiles = { "${workspaceFolder}/node_modules/**" },
  },
}

-- c / c++
dap.configurations.cpp = {
  {
    type = "codelldb",
    request = "launch",
    name = "Launch executable",
    program = inputExecutable,
    cwd = "${workspaceFolder}",
  },
  {
    type = "codelldb",
    request = "launch",
    name = "Launch executable with args",
    program = inputExecutable,
    cwd = "${workspaceFolder}",
    args = "${command:SpecifyProgramArgs}",
  },
  {
    type = "codelldb",
    request = "attach",
    name = "Attach",
    pid = require("dap.utils").pick_process,
    cwd = "${workspaceFolder}",
  },
}
dap.configurations.c = dap.configurations.cpp

-- VS Code launch.json calls this property `envFile` (string, or string[] for Java).
-- It is contributed by each debugger, not by the DAP protocol.
-- debugpy/python: nvim-dap-python reads `envFile` and ignores a missing file.
-- node/pwa-node (js-debug) and codelldb read `envFile` and fail the launch if it is missing,
-- so drop the property when the file is not there.
-- Go (Delve) and Java only accept `env`. vscode-go and vscode-java fold `envFile` into `env` first;
-- do the same here. `env` entries win over the file, matching those extensions.
local adapter_errors_if_env_file_missing = {
  node = true,
  ["pwa-node"] = true,
  codelldb = true,
  lldb = true,
}

local client_folds_env_file = {
  go = true,
  java = true,
}

---@param path string
---@return table<string, string>?
local function read_env_file(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local env = {}
  for line in file:lines() do
    line = line:gsub("\r$", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if line ~= "" and line:sub(1, 1) ~= "#" then
      line = line:gsub("^export%s+", "")
      local key, value = line:match("^([%w_.]+)%s*=%s*(.*)$")
      if key then
        if #value >= 2 then
          local quote = value:sub(1, 1)
          if (quote == '"' or quote == "'") and value:sub(-1) == quote then
            value = value:sub(2, -2)
          end
        end
        env[key] = value
      end
    end
  end
  file:close()
  return env
end

---@param path string
---@return string?
local function expand_env_file_path(path)
  local expanded = path
  local replacements = {
    { "%${workspaceFolderBasename}", vim.fn.fnamemodify(vim.fn.getcwd(), ":t") },
    { "%${workspaceFolder}", vim.fn.getcwd() },
    { "%${fileDirname}", vim.fn.expand("%:p:h") },
    { "%${file}", vim.fn.expand("%:p") },
  }
  for _, item in ipairs(replacements) do
    expanded = expanded:gsub(item[1], function()
      return item[2]
    end)
  end
  expanded = expanded:gsub("%${env:([%w_]+)}", function(name)
    return os.getenv(name) or ""
  end)
  if expanded:find("${", 1, true) then
    return nil
  end
  return vim.fn.fnamemodify(expanded, ":p")
end

---@param value any
---@return string[]
local function env_file_list(value)
  if type(value) == "string" then
    return value ~= "" and { value } or {}
  end
  if type(value) == "table" then
    local paths = {}
    for _, item in ipairs(value) do
      if type(item) == "string" and item ~= "" then
        table.insert(paths, item)
      end
    end
    return paths
  end
  return {}
end

dap.listeners.on_config["envFile"] = function(config)
  if config.envFile == nil or config.envFile == vim.NIL then
    return config
  end
  local drops_missing = adapter_errors_if_env_file_missing[config.type]
  local folds = client_folds_env_file[config.type]
  if not drops_missing and not folds then
    return config
  end

  local paths = env_file_list(config.envFile)
  local expanded = {}
  local unresolved = false
  for _, path in ipairs(paths) do
    local full = expand_env_file_path(path)
    if not full then
      unresolved = true
    else
      table.insert(expanded, full)
    end
  end

  if drops_missing then
    if unresolved then
      return config
    end
    for _, path in ipairs(expanded) do
      if vim.fn.filereadable(path) == 0 then
        config = vim.deepcopy(config)
        config.envFile = nil
        return config
      end
    end
    return config
  end

  config = vim.deepcopy(config)

  local from_files = {}
  for _, path in ipairs(expanded) do
    local parsed = read_env_file(path)
    if parsed then
      from_files = vim.tbl_extend("force", from_files, parsed)
    end
  end
  if next(from_files) then
    config.env = vim.tbl_extend("force", from_files, config.env or {})
  end
  if not unresolved then
    config.envFile = nil
  end
  return config
end
