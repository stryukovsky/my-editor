local map = require "mappings.map"
local minidiff = require "configs.minidiff"
local navigation_repeat = require "utils.navigation_repeat"

map("n", "<leader>gr", minidiff.reset_hunk, { desc = "git hunk reset" })
map("n", "<leader>gh", function()
  require("configs.large_hunks_viewer").view_hunk()
end, { desc = "git view hunk" })
map("n", "<leader>gv", minidiff.select, { desc = "git select hunk" })
map("n", "<leader>gR", minidiff.reset_buffer, { desc = "git reset buffer" })

map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })

map("n", "]g", function()
  navigation_repeat.run(function()
    minidiff.nav(1)
  end, "next git hunk")
end, { desc = "Jump to next git hunk" })

map("n", "[g", function()
  navigation_repeat.run(function()
    minidiff.nav(-1)
  end, "prev git hunk")
end, { desc = "Jump to prev git hunk" })

map("n", "<A-h>", minidiff.toggle_overlay, { desc = "git toggle hunk overlay" })

map("n", "<leader>gC", function()
  require("configs.minidiff_review").open_picker()
end, { desc = "git review source into target" })

map("n", "<leader>gH", function()
  require("configs.minidiff_history").open()
end, { desc = "git review branch history" })
