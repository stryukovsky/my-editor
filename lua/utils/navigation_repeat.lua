local M = {}
local notify = require "configs.notify"
local last_navigation_name
-- last navigation function which advances by buffer
local last_next

-- last navigation function which goes backwards
local last_previous

-- these ones are paired: if last next was "next diagnostic" then last previous automatically will be "previous diagnostic"

---@param next_navigation fun()
---@param previous_navigation fun()
---@param navigation_name string
function M.set(next_navigation, previous_navigation, navigation_name)
  last_next = next_navigation
  last_previous = previous_navigation
  last_navigation_name = navigation_name
end

---@param direction "next"|"previous"
local function repeat_navigation(direction)
  local navigation = direction == "next" and last_next or last_previous
  if navigation then
    notify.replace("navigation-repeat", "Navigation", ("Repeat %s: %s"):format(direction, last_navigation_name), vim.log.levels.INFO)
    navigation()
  else
    notify.replace("navigation-repeat", "Navigation", "Nothing to repeat")
  end
end

function M.repeat_next()
  repeat_navigation "next"
end

function M.repeat_previous()
  repeat_navigation "previous"
end

return M
