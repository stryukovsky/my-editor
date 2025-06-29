-- Lua
local grapple = require "grapple"
vim.keymap.set("n", "mm", grapple.toggle, { desc = "Marks add" })
vim.keymap.set("n", "ma", grapple.toggle, { desc = "Marks add" })
vim.keymap.set("n", "mx", grapple.reset, { desc = "Marks purge" })
vim.keymap.set("n", "md", grapple.reset, { desc = "Marks purge" })
vim.keymap.set("n", "]m", function()
  grapple.cycle_tags "next"
end, { desc = "Marks next tag" })

vim.keymap.set("n", "[m", function()
  grapple.cycle_tags "prev"
end, { desc = "Marks prev tag" })
for i = 1, 9 do
  vim.keymap.set("n", "m" .. tostring(i), "<cmd>Grapple select index=" .. tostring(i) .. "<cr>")
end
