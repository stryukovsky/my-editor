local create_float_input = require "ui.float_input"

return function()
  create_float_input("commit message", "", function(value)
    local response = vim.fn.system('git commit -m "' .. value .. '"')
    vim.print(response)
  end)
end
