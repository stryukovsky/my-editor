local M = {}
local notify = require("configs.notify")
local last_navigation

---@param navigation fun()
function M.run(navigation)
  last_navigation = navigation
  navigation()
end

function M.repeat_last()
    notify.send("idk", "idk", vim.log.levels.INFO)
  if last_navigation then
    last_navigation()
  end
end

return M
