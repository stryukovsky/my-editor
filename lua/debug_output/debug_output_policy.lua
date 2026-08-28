-- DAP adapters do not share a standard console/output option. These launch
-- defaults keep debuggee output in DAP `output` events for debug_output and
-- prevent nvim-dap from creating a terminal unless a configuration explicitly
-- opts into a different behavior.
--
-- `nil` means absent. Any value provided by a project or user configuration,
-- including an empty string, is preserved as-is.
local settings = require "debug_output.config"

return function(config)
  if not config then
    return config
  end

  local policy = settings.options.output_policy[config.type]
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
