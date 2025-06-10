---@diagnostic disable: missing-fields
local dbee = require "dbee"
local sources = require "dbee.sources"
local urldb   = require "ui.urldb"
-- local dburl = require "ui.dburl"

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
  local bind_fn = function (url)
    vim.print(url)
    create_connection(current_dir_name, type, url)
  end
  urldb(bind_fn)
  -- vim.ui.input()
end
