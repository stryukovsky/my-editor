local M = {}

local function inputCommand()
  return vim.fn.input "Command:"
end

local function inputExecutable()
  return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/", "file")
end

function M.javascript()
  return {
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
end

function M.typescript()
  return {
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
end

function M.cpp()
  return {
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
end

-- Rust uses the same executable/attach presets and CodeLLDB adapter as C/C++.
function M.rust()
  return M.cpp()
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
M.node = js_debug

M.codelldb = {
  type = "server",
  -- CodeLLDB listens on IPv4; localhost can resolve to ::1 first.
  host = "127.0.0.1",
  port = "${port}",
  executable = {
    command = "codelldb",
    args = { "--port", "${port}" },
  },
}

function M.python()
  return {
    {
      type = "python",
      request = "launch",
      name = "Run Command",
      program = "${file}",
      cwd = "${workspaceFolder}",
      envFile = "${workspaceFolder}/.env",
      runtimeExecutable = inputCommand,
    },
    {
      type = "python",
      request = "launch",
      name = "Run file",
      program = "${file}",
      cwd = "${workspaceFolder}",
      envFile = "${workspaceFolder}/.env",
    },
  }
end

function M.go()
  return {
    {
      type = "go",
      request = "launch",
      name = "Debug file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "go",
      request = "launch",
      name = "Debug package",
      program = "${fileDirname}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "go",
      request = "launch",
      name = "Debug test",
      mode = "test",
      program = "${fileDirname}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "go",
      request = "attach",
      name = "Attach",
      mode = "local",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end

function M.java()
  return {
    {
      type = "java",
      request = "launch",
      name = "Java: current file",
      mainClass = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "java",
      request = "attach",
      name = "Java: attach JDWP (5005)",
      hostName = "localhost",
      port = 5005,
      cwd = "${workspaceFolder}",
    },
  }
end

function M.scala()
  return {
    {
      type = "scala",
      cwd = "${workspaceFolder}",
      request = "launch",
      name = "RunOrTest",
      metals = {
        runType = "runOrTestFile",
        --args = { "firstArg", "secondArg", "thirdArg" }, -- here just as an example
      },
    },
    {
      type = "scala",
      cwd = "${workspaceFolder}",
      request = "launch",
      name = "Test Target",
      metals = {
        runType = "testTarget",
      },
    },
    {
      type = "scala",
      cwd = "${workspaceFolder}",
      request = "launch",
      name = "Sbt run",
      metals = {
        shellCommand = "sbt run",
      },
    },
  }
end

return M
