local dbee = require "dbee"
local sources = require "dbee.sources"
local dburl = require "ui.dburl"

local function create_connection(name, type, url)
  dbee.setup {
    sources = {
      sources.MemorySource:new {
        {
          name = name,
          type = type,
          url = url,
        },
      },
    },
  }
  dbee.open()
end

return function(type)
  local current_dir_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  dburl(current_dir_name, type, create_connection)
end
