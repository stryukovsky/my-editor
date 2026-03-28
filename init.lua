---@diagnostic disable: duplicate-set-field
vim.g.mapleader = " "
vim.opt.termguicolors = true

local config_dir = vim.fn.stdpath "config"

vim.fn.setenv("XDG_DATA_HOME", config_dir)
vim.g.netrw_home = config_dir .. "/data"

local original_stdpath = vim.fn.stdpath
vim.fn.stdpath = function(what)
  if what == "data" then
    return config_dir .. "/data"
  else
    return original_stdpath(what)
  end
end

-- Create directories if they don't exist
local dirs_to_create = {
  config_dir .. "/data",
}

for _, dir in ipairs(dirs_to_create) do
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end

local lazypath = config_dir .. "/data/lazy/lazy.nvim"
if vim.fn.isdirectory(lazypath) == 0 then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- Configure lazy.nvim to use our custom data directory
require("lazy").setup({
  { import = "plugins" },
}, {
  root = config_dir .. "/data/lazy",
  lockfile = config_dir .. "/lazy-lock.json",
})

vim.opt.undofile = true

require "options"
require "configs"
require "mappings"
require "theme"

-- at the end of config we auto remap already defined mappings so Russian keyboard is acceptable
local langmapper = require "langmapper"
langmapper.automapping { global = true, buffer = true }
