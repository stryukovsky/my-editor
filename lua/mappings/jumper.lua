local map = require "mappings.map"
local jumper = require "moonshine.jumper"

for code = string.byte("a"), string.byte("z") do
  local name = string.char(code)
  map("n", "m" .. name, function()
    jumper.set(name)
  end, { desc = "Set global mark " .. name })
  map("n", "'" .. name, function()
    jumper.jump(name)
  end, { desc = "Jump to global mark " .. name })
end

map("n", "]m", function()
  jumper.navigate(1, vim.v.count1)
end, { desc = "Next global mark alphabetically" })
map("n", "[m", function()
  jumper.navigate(-1, vim.v.count1)
end, { desc = "Previous global mark alphabetically" })
map("n", "dm", jumper.delete_line, { desc = "Delete marks on this line" })
map("n", "<leader>dm", jumper.delete_file, { desc = "Delete marks in this file" })
map("n", "<leader>maa", jumper.add_next, { desc = "Add next unused global mark" })
map("n", "<leader>mad", jumper.delete_all, { desc = "Delete all global marks" })
