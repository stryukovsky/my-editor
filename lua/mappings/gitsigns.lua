local map = require "mappings.map"
local gitsigns = require "gitsigns"

-- gitsigns
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "git hunk reset" })
map("n", "<leader>gh", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "git hunk preview" })

-- map("n", "<leader>gs", "<cmd>Gitsigns stage_buffer<cr>", { desc = "git stage buffer" })
map("n", "<leader>gv", "<cmd>Gitsigns select_hunk<cr>", { desc = "git select buffer" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "git reset buffer" })
-- map("n", "<leader>bl", "<cmd>Gitsigns blame_line<cr>", { desc = "git blame line" })

local function center_hunk()
  vim.defer_fn(function()
    vim.cmd "normal! zz"
  end, 10)
  vim.defer_fn(function()
    gitsigns.preview_hunk_inline()
  end, 20)

end
map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })

map("n", "]g", function()
  if vim.wo.diff then
    vim.cmd.normal { "]c", bang = true }
  else
    gitsigns.nav_hunk "next"
  end
  center_hunk()
end, { desc = "Jump To the git next hunk" })

map("n", "[g", function()
  if vim.wo.diff then
    vim.cmd.normal { "[c", bang = true }
  else
    gitsigns.nav_hunk "prev"
  end
  center_hunk()
end, { desc = "Jump To the git prev hunk" })
