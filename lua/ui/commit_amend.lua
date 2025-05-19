local create_float_input = require "ui.float_input"

local function all_trim(s)
  return s:match("^%s*(.*)"):match "(.-)%s*$"
end

return function()
  create_float_input("amend commit? (y/n)", "", function(value)
    local agreed = all_trim(value)
    if agreed == "y" or agreed == "Y" or agreed == "" then
      local response = vim.fn.system "git commit --amend --no-edit"
      vim.print(response)
    end
  end)
end
