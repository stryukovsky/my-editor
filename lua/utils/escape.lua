local clear_selections = require "utils.clear_selections"

return function()
  -- Dismiss visible notifications and discard queued ones.
  require("notify").dismiss { silent = true, pending = true }
  clear_selections()
end
