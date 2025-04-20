local create_float_input = require "ui.float_input"

return function()
  create_float_input("new branch", "", function(value)
    local response = vim.fn.system("git checkout -b " .. value)
    vim.print(response)
  end)
end
