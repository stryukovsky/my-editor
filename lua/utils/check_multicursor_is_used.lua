local multicursor_namespace = vim.api.nvim_create_namespace "nvim.multicursor"

return function()
  return #vim.api.nvim_buf_get_extmarks(
    0,
    multicursor_namespace,
    0,
    -1,
    { limit = 1 }
  ) > 0
end
