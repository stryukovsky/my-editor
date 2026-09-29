local dap = require "dap"

local function inputCommand()
  return vim.fn.input "Command:"
end

local function inputExecutable()
  return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
end

-- js/typescript adapter
dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "${port}",
  executable = {
    command = "js-debug-adapter",
    args = { "${port}" },
  },
}

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
