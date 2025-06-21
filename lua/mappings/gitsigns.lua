local map = require "mappings.map"

-- gitsigns
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "git hunk reset" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "git hunk preview" })

map("n", "<leader>gs", "<cmd>Gitsigns stage_buffer<cr>", { desc = "git stage buffer" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "git reset buffer" })
-- map("n", "<leader>bl", "<cmd>Gitsigns blame_line<cr>", { desc = "git blame line" })

map("n", "]g", "<cmd>Gitsigns next_hunk<cr>", { desc = "Jump To the git next hunk" })
map("n", "[g", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Jump To the git prev hunk" })

map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })
