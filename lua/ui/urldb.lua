local Input = require "nui.input"
local event = require("nui.utils.autocmd").event
local dbee = require "dbee"
local sources = require "dbee.sources"

return function(dbtype)
  local protocol = "postgresql"
  if dbtype == "postgres" then
    protocol = "postgresql"
  end
  local current_dir_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  local input = Input({
    position = "50%",
    size = {
      width = 90,
    },
    border = {
      style = "single",
      text = {
        top = "[DB Url]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    prompt = "> ",
    default_value = protocol .. "://postgres:postgres@localhost:5432/postgres",
    on_close = function() end,
    on_submit = function(value)
      dbee.setup {
        sources = {
          sources.MemorySource:new {
            ---@diagnostic disable-next-line: missing-fields
            {
              name =current_dir_name,
              type = dbtype,
              url = value,
            },
          },
        },
      }
      dbee.open()
    end,
  })

  -- mount/open the component
  input:mount()

  -- unmount component when cursor leaves buffer
  input:on(event.BufLeave, function()
    input:unmount()
  end)
end
