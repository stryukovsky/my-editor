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

require("dapui").setup {
  controls = {
    element = "repl",
    enabled = true,
    icons = {
      disconnect = "",
      pause = "",
      play = "",
      run_last = "",
      step_back = "",
      step_into = "",
      step_out = "",
      step_over = "",
      terminate = "",
    },
  },
  element_mappings = {},
  expand_lines = true,
  floating = {
    border = "single",
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  force_buffers = true,
  icons = {
    collapsed = "",
    current_frame = "",
    expanded = "",
  },
  layouts = {
    {
      elements = {
        {
          id = "scopes",
          size = 0.40,
        },
        {
          id = "stacks",
          size = 0.35,
        },
        {
          id = "breakpoints",
          size = 0.25,
        },
        -- {
        --   id = "watches",
        --   size = 0.25,
        --   enabled = false
        -- },
      },
      position = "left",
      size = 40,
    },
    {
      elements = {
        -- {
        --   id = "repl",
        --   size = 0.5,
        -- },
        {
          id = "repl",
          size = 1,
        },
      },
      position = "bottom",
      size = 15,
    },
  },
  mappings = {
    edit = "e",
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    repl = "r",
    toggle = "t",
  },
  render = {
    indent = 1,
    max_value_lines = 100,
  },
}

require("render-markdown").setup {
  file_types = { "markdown", "quarto" },
}

vim.cmd [[
:hi link   NvimTreeExecFile            NvimTreeNormal              
:hi link   NvimTreeImageFile           NvimTreeNormal              
:hi link   NvimTreeSpecialFile         NvimTreeNormal              
:hi link   NvimTreeSymlink             NvimTreeNormal              
:hi   NvimTreeGitDeletedIcon      guifg=#ff0000 
:hi   NvimTreeGitDirtyIcon        guifg=#ffff00 
:hi   NvimTreeGitIgnoredIcon      guifg=#b0b0b0
:hi   NvimTreeGitMergeIcon        guifg=#ffff00
:hi   NvimTreeGitNewIcon          guifg=#00ff00 
:hi   NvimTreeGitRenamedIcon      guifg=#ffff00 
:hi   NvimTreeGitStagedIcon       guifg=#00ffff 
]]
