local map = require "mappings.map"

-- Save cwd (neo-tree root, else getcwd) into projects.json. Does not open a Kitty tab.
map("n", "<leader>prj", function()
  require("configs.projects").mark()
end, { desc = "Projects mark current root" })
