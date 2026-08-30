local M = {}
local notify = require "configs.notify"
local last_navigation_name
local last_navigation

---@param navigation fun()
---@param navigation_name string
function M.run(navigation, navigation_name)
  last_navigation = navigation
  last_navigation_name = navigation_name
  navigation()
end

function M.repeat_last()
  if last_navigation then
    notify.replace("navigation-repeat", "Navigation", "Repeat: " .. last_navigation_name, vim.log.levels.INFO)
    last_navigation()
  else
    notify.replace("navigation-repeat", "Navigation", "Nothing to repeat")
  end
end

return M
