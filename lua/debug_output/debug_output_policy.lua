-- DAP adapters do not share a standard console/output option. These launch
-- defaults keep debuggee output in DAP `output` events for debug_output and
-- prevent nvim-dap from creating a terminal unless a configuration explicitly
-- opts into a different behavior.
--
-- `nil` means absent. Any value provided by a project or user configuration,
-- including an empty string, is preserved as-is.
local output_policy = {
  java = {
    -- Java Debug: `internalConsole` | `integratedTerminal` | `externalTerminal`
    defaults = { console = "internalConsole" },
  },
  ["pwa-node"] = {
    -- js-debug: console destination; `std` captures process stdout/stderr.
    defaults = { console = "internalConsole", outputCapture = "std" },
  },
  python = {
    -- debugpy: console destination; redirectOutput forwards stdout/stderr.
    defaults = { console = "internalConsole", redirectOutput = true },
  },
  debugpy = {
    -- `debugpy` is also used by existing launch.json templates.
    defaults = { console = "internalConsole", redirectOutput = true },
  },
  go = {
    -- Delve: `remote` emits debuggee stdout/stderr as DAP output events.
    defaults = { outputMode = "remote" },
  },
  codelldb = {
    -- CodeLLDB: `console` | `integrated` | `external`.
    defaults = { terminal = "console" },
  },
  scala = {
    -- Metals already emits debuggee output as DAP output events.
    defaults = {},
  },
}

return function(config)
  if not config then
    return config
  end

  local policy = output_policy[config.type]
  if not policy or config.request ~= "launch" then
    return config
  end

  local effective_config = vim.deepcopy(config)
  for key, value in pairs(policy.defaults) do
    if effective_config[key] == nil then
      effective_config[key] = value
    end
  end
  return effective_config
end
