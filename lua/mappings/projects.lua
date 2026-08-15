local map = require "mappings.map"

map("n", "<leader>prj", function()
  require("configs.projects").mark()
end, { desc = "Projects mark current root" })
