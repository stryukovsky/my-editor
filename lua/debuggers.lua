-- require("dap-vscode-js").setup {
--   -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
--   debugger_path = "~/.local/share/nvim/mason/packages/js-debug-adapter", -- Path to vscode-js-debug installation.
--   -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
--   adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }, -- which adapters to register in nvim-dap
--   -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
--   -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
--   -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
--   --
-- }
--
--
-- dap.configurations.lua = {
--   {
--     type = "nlua",
--     request = "attach",
--     name = "Attach to running Neovim instance",
--     host = function()
--       local value = vim.fn.input "Host [127.0.0.1]: "
--       if value ~= "" then
--         return value
--       end
--       return "127.0.0.1"
--     end,
--     port = function()
--       local val = tonumber(vim.fn.input "Port: ")
--       assert(val, "Please provide a port number")
--       return val
--     end,
--   },
-- }
--
local dap = require("dap")

dap.adapters["pwa-node"] = {
  type = "server",
  host = "localhost",
  port = "8123",
  command = "bash /Users/dmitry/.local/share/nvim/mason/packages/js-debug-adapter/js-debug-adapter",
  -- executable = {
  --   command = vim.fn.exepath "js-debug-adapter",
  --   args = { "50119" },
  -- },
}

for _, language in ipairs { "typescript", "javascript" } do
  dap.configurations[language] = {
    {
      type = "pwa-node",
      request = "launch",
      name = "Launch file",
      program = "${file}",
      cwd = "${workspaceFolder}",
    },
    {
      type = "pwa-node",
      request = "attach",
      name = "Attach",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
end
