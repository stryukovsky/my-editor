---@diagnostic disable-next-line: missing-fields
require("nvim-treesitter").setup {
  auto_install = false,
  install_dir = vim.fn.stdpath "data" .. "/treesitter",
}
