local create_float_input = require "ui.float_input"

return function(name, type, fn_create_connection)
  create_float_input(
    "db uri " .. "(" .. type .. ")",
    "postgres://u:p@localhost:5432/postgres?sslmode=disable",
    function(value)
      fn_create_connection(name, type, value)
    end
  )
end
