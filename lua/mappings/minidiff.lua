local map = require "mappings.map"
local minidiff = require "configs.minidiff"

map("n", "<leader>gr", minidiff.reset_hunk, { desc = "git hunk reset" })
map("n", "<leader>gh", minidiff.preview, { desc = "git hunk preview" })
map("n", "<leader>gv", minidiff.select, { desc = "git select hunk" })
map("n", "<leader>gR", minidiff.reset_buffer, { desc = "git reset buffer" })

map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })

map("n", "]g", function()
  minidiff.nav(1)
end, { desc = "Jump to next git hunk" })

map("n", "[g", function()
  minidiff.nav(-1)
end, { desc = "Jump to prev git hunk" })

map("n", "<leader>gC", function()
  require("configs.minidiff_review").open_picker()
end, { desc = "git compare two refs" })
