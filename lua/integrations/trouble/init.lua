local M = {}

function M.setup()
  local sources = require "trouble.sources"
  for _, name in ipairs { "dap_breakpoints", "minidiff_review" } do
    if not sources.sources[name] then
      sources.register(name, require("integrations.trouble.sources." .. name))
    end
  end
end

return M
