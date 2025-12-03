vim.g.mapleader = " "
-- End of init.lua script.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
-- bootstrap lazy and all plugins

-- Place this at the top of your init.lua (~/.config/nvim/init.lua)
-- This redirects all data directories to stay within ~/.config/nvim

local config_dir = vim.fn.stdpath('config')

-- Override standard paths to use config directory
vim.opt.runtimepath:prepend(config_dir .. '/runtime')
vim.opt.packpath:prepend(config_dir .. '/runtime')

-- Set data directory within config
vim.fn.setenv('XDG_DATA_HOME', config_dir)
vim.g.netrw_home = config_dir .. '/data'

-- Override stdpath function to redirect data paths
local original_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(what)
  if what == 'data' then
    return config_dir .. '/data'
  elseif what == 'state' then
    return config_dir .. '/state'
  elseif what == 'cache' then
    return config_dir .. '/cache'
  else
    return original_stdpath(what)
  end
end

-- Create directories if they don't exist
local dirs = {
  config_dir .. '/data',
  config_dir .. '/state',
  config_dir .. '/cache',
  config_dir .. '/runtime',
}

for _, dir in ipairs(dirs) do
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

-- Plugin manager specific configurations
-- For lazy.nvim (if you use it)
local lazypath = config_dir .. '/data/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim to use our custom data directory
require('lazy').setup({
  {import = "plugins"},
}, {
  root = config_dir .. '/data/lazy',
  lockfile = config_dir .. '/lazy-lock.json',
})

-- For packer.nvim (if you use it instead)
-- local packer_path = config_dir .. '/data/site/pack/packer/start/packer.nvim'
-- if vim.fn.empty(vim.fn.glob(packer_path)) > 0 then
--   vim.fn.system({'git', 'clone', '--depth', '1', 
--     'https://github.com/wbthomason/packer.nvim', packer_path})
-- end

-- LSP server installations (for mason.nvim if you use it)
require('mason').setup({
  install_root_dir = config_dir .. '/data/mason',
})

-- TreeSitter parsers
-- require('nvim-treesitter.configs').setup({
--   parser_install_dir = config_dir .. '/data/treesitter',
--   -- Your treesitter config here
-- })
-- vim.opt.runtimepath:append(config_dir .. '/data/treesitter')

-- Set shada (shared data) file location
vim.opt.shadafile = config_dir .. '/state/shada/main.shada'

-- Set undo directory
vim.opt.undodir = config_dir .. '/state/undo'
vim.opt.undofile = true

-- Set backup and swap directories
vim.opt.backupdir = config_dir .. '/state/backup'
vim.opt.directory = config_dir .. '/state/swap'

require "options"
require "configs"
require "mappings"
require "theme"

-- at the end of config we auto remap already defined mappings so Russian keyboard is acceptable
local langmapper = require "langmapper"
langmapper.automapping { global = true, buffer = true }
