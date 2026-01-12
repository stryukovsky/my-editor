return function()
  return pcall(function()
    vim.system({ "ollama" }):wait()
  end)
end
