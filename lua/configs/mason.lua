local config_dir = vim.fn.stdpath "config"

require("mason").setup {
  install_root_dir = config_dir .. "/data/mason",
}

