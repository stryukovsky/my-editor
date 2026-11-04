local wrap_telescope_action = require "mappings.telescope_action_wrapper"
local trouble_integration = require "mappings.telescope.trouble_integration"

local open_results = wrap_telescope_action(trouble_integration "ripgrep_results")

return {
  n = {
    ["<cr>"] = open_results,
    ["<A-t>"] = open_results,
  },
  i = {
    ["<cr>"] = open_results,
    ["<A-t>"] = open_results,
  },
}
