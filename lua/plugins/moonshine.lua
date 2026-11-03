-- Local plugins expose Lua modules; configs/init.lua preserves their setup order.
local plugins = {}
local root = vim.fn.stdpath "config" .. "/moonshine.nvim"

for _, dir in ipairs(vim.fn.globpath(root, "*", false, true)) do
  if vim.fn.isdirectory(dir .. "/lua") == 1 then
    plugins[#plugins + 1] = {
      dir = dir,
      name = "moonshine-" .. vim.fn.fnamemodify(dir, ":t"),
      lazy = false,
    }
  end
end

return plugins
