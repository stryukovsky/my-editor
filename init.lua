vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

require("dap-go").setup()

require("gomove").setup {
  -- whether or not to map default key bindings, (true/false)
  map_defaults = false,
  -- whether or not to reindent lines moved vertically (true/false)
  reindent = true,
  -- whether or not to undo join same direction moves (true/false)
  undojoin = true,
  -- whether to not to move past end column when moving blocks horizontally, (true/false)
  move_past_end_col = false,
}

require "configs.debuggers"

require("configs.dapui")

require("render-markdown").setup {
  file_types = { "markdown", "quarto" },
}

vim.cmd [[
:hi link   NvimTreeExecFile            NvimTreeNormal              
:hi link   NvimTreeImageFile           NvimTreeNormal              
:hi link   NvimTreeSpecialFile         NvimTreeNormal              
:hi link   NvimTreeSymlink             NvimTreeNormal              
:hi        NvimTreeGitDeletedIcon      guifg=#ff4e33
:hi link   NvimTreeGitDirtyIcon        PreProc
:hi link   NvimTreeGitIgnoredIcon      Comment 
:hi link   NvimTreeGitMergeIcon        PreProc
:hi        NvimTreeGitNewIcon          guifg=#138808
:hi link   NvimTreeGitRenamedIcon      PreProc
:hi link   NvimTreeGitStagedIcon       PreProc 
]]

