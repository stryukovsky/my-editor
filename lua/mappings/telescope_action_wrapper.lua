local close_telescope = require "mappings.close_telescope"

return function(fn)
-- this function is a constructor of functions which accept "bufnr" - argument of telescope action
  return function(bufnr)
    if not pcall(fn, bufnr) then
      close_telescope()
      vim.g.last_opened_telescope = ""
    end
  end
end
