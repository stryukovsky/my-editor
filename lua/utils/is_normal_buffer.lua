return function()
  local bufnr = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_get_option_value("buflisted", { buf = bufnr }) then
    return false
  end

  local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
  if buftype ~= "" then
    return false
  end

  local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
  local excluded_filetypes = {
    "neogit",
    "neogitcommit",
    "neogitpopup",
    "neo-tree",
    "neo-tree-popup",
    "neotest-summary",
    "neotest-output",
    "telescope",
    "TelescopePrompt",
    "oil",
    "toggleterm",
    "lazy",
    "mason",
    "help",
    "qf",
    "fugitive",
    "git",
  }

  for _, ft in ipairs(excluded_filetypes) do
    if filetype == ft then
      return false
    end
  end

  -- Check if buffer has a real filepath
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if filepath == "" then
    return false
  end

  return true
end
