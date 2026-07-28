local M = {}

function M.setup()
  vim.notify = require "notify"
end

function M.send(title, message, level)
  require("notify")(message, level or vim.log.levels.INFO, { title = title })
end

return M
