return function()
  -- Получаем координаты начала и конца выделения
  local s = vim.fn.getpos "v"
  local e = vim.fn.getpos "."

  -- Получаем текущий режим (v, V или CTRL-V)
  local mode = vim.fn.mode()

  -- Извлекаем текст
  local lines = vim.fn.getregion(s, e, { type = mode })
  return table.concat(lines, "\n")
end
