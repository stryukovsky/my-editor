local map = require "mappings.map"

-- gitsigns
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "git hunk reset" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "git hunk preview" })

map("n", "<leader>gs", "<cmd>Gitsigns stage_buffer<cr>", { desc = "git stage buffer" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "git reset buffer" })
map("n", "<leader>bl", "<cmd>Gitsigns blame_line<cr>", { desc = "git blame line" })

map("n", "]g", "<cmd>Gitsigns next_hunk<cr>", { desc = "Jump To the git next hunk" })
map("n", "[g", "<cmd>Gitsigns prev_hunk<cr>", { desc = "Jump To the git prev hunk" })

map("n", "<leader>gPush", function()
  vim.system({ "git", "push", "--set-upstream", "origin", "$(git rev-parse --abbrev-ref HEAD)" }, {}, function(response)
    print(response.stdout)
  end)
end, { desc = "git push" })

map("n", "<leader>gPull", function()
  vim.system({ "git", "pull"}, {}, function(response)
    print(response.stdout)
  end)
end, { desc = "git pull" })

map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })
