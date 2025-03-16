local dap = require "dap"

local function inputCommand()
  vim.fn.input "Command:"
end

-- js/typescript adapter
dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "8123",
  command = "",
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

-- scala
dap.configurations.scala = {
  {
    type = "scala",
    request = "launch",
    name = "RunOrTest",
    metals = {
      runType = "runOrTestFile",
      --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
    },
  },
  {
    type = "scala",
    request = "launch",
    name = "Test Target",
    metals = {
      runType = "testTarget",
    },
  },
}
