-- Native Q, zq{motion}, gQ and Ctrl-click are provided by Neovim 0.13.
if vim.fn.has "nvim-0.13" == 0 then
  return
end

local map = require "mappings.map"
local escape = require "utils.escape"
local namespace = vim.api.nvim_create_namespace "nvim.multicursor"
local technical_filetypes = {}
for _, filetype in ipairs(require "moonshine.utils.technical_ui_filetypes") do
  technical_filetypes[filetype] = true
end

-- Keep plugin-local mappings intact and guard only the native defaults.
for _, key in ipairs { "Q", "zq", "gQ", "<C-LeftMouse>" } do
  map({ "n", "x" }, key, function()
    local buf = vim.api.nvim_get_current_buf()
    if key == "<C-LeftMouse>" then
      local win = vim.fn.getmousepos().winid
      if win ~= 0 and vim.api.nvim_win_is_valid(win) then
        buf = vim.api.nvim_win_get_buf(win)
      end
    end
    if
      vim.bo[buf].buftype ~= "" or technical_filetypes[vim.bo[buf].filetype]
    then
      return ""
    end
    return key
  end, { expr = true, desc = "Multicursor: editing buffers only" })
end

map("n", "<Esc>", function()
  vim.api.nvim_buf_clear_namespace(0, namespace, 0, -1)
  escape()
end, { desc = "clear multicursors, highlights and notifications" })
