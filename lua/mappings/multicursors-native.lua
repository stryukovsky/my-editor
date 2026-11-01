-- Native Q, zq{motion}, gQ and Ctrl-click are provided by Neovim 0.13.
if vim.fn.has "nvim-0.13" == 0 then
  return
end

local map = require "mappings.map"
local escape = require "utils.escape"
local namespace = vim.api.nvim_create_namespace "nvim.multicursor"

map("n", "<Esc>", function()
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
  escape()
end, { desc = "clear multicursors, highlights and notifications" })
