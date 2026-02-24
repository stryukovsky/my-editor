local wrap_telescope_action = require "mappings.telescope_action_wrapper"
local trouble_integration = require("mappings.telescope.trouble_integration")

return {
  n = {
    ["<cr>"] = wrap_telescope_action(trouble_integration),
  },
  i = {
    ["<cr>"] = wrap_telescope_action(trouble_integration),
  },
}
