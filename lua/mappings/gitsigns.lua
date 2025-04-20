local map = require "mappings.map"

-- gitsigns
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "git hunk reset" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "git hunk preview" })

map("n", "<leader>gs", "<cmd>Gitsigns stage_buffer<cr>", { desc = "git stage buffer" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "git reset buffer" })
map("n", "<leader>gB", "<cmd>Gitsigns blame<cr>", { desc = "git blame buffer" })
map("n", "<leader>bl", "<cmd>Gitsigns blame_line<cr>", { desc = "git blame line" })

map("n", "g<Down>", "<cmd>Gitsigns next_hunk<cr>", { desc = "git next hunk" })
map("n", "g<Up>", "<cmd>Gitsigns prev_hunk<cr>", { desc = "git prev hunk" })

map("n", "<leader>gP", function()
  local response = vim.fn.system "git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD) "
  print(response)
end, { desc = "git push" })

map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })
