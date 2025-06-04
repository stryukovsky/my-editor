vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true

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
  { import = "plugins" },
}, lazy_config)

require "options"
-- require "nvchad.autocmds"

vim.schedule(function()
  require "mappings"
end)

require "configs"

-- Function to close empty and unnamed buffers
local function close_empty_unnamed_buffers()
  -- Get a list of all buffers
  local buffers = vim.api.nvim_list_bufs()

  -- Iterate over each buffer
  for _, bufnr in ipairs(buffers) do
    -- Check if the buffer is empty and doesn't have a name
    if
      vim.api.nvim_buf_is_loaded(bufnr)
      and vim.api.nvim_buf_get_name(bufnr) == ""
      and vim.api.nvim_buf_get_option(bufnr, "buftype") == ""
    then
      -- Get all lines in the buffer
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Initialize a variable to store the total number of characters
      local total_characters = 0

      -- Iterate over each line and calculate the number of characters
      for _, line in ipairs(lines) do
        total_characters = total_characters + #line
      end

      -- Close the buffer if it's empty:
      if total_characters == 0 then
        vim.api.nvim_buf_delete(bufnr, {
          force = true,
        })
      end
    end
  end
end

-- Clear the mandatory, empty, unnamed buffer when a real file is opened:
-- vim.api.nvim_command('autocmd BufReadPost * lua require()

vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(args)
    close_empty_unnamed_buffers()
  end,
})

-- vim.api.nvim_create_autocmd("VimEnter", {
--   callback = function(args)
--     current_hour = tonumber(tostring(vim.fn.strftime "%H"))
--     if current_hour >= 22 then
--       vim.cmd "colorscheme tokyonight-night"
--     else
--       vim.cmd "colorscheme tokyonight-day"
--     end
--   end,
-- })
