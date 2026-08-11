local map = require "mappings.map"
local gitsigns = require "gitsigns"
local popup = require "gitsigns.popup"

-- gitsigns
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "git hunk reset" })
map("n", "<leader>gh", "<cmd>Gitsigns preview_hunk<cr>", { desc = "git hunk preview" })

-- map("n", "<leader>gs", "<cmd>Gitsigns stage_buffer<cr>", { desc = "git stage buffer" })
map("n", "<leader>gv", "<cmd>Gitsigns select_hunk<cr>", { desc = "git select buffer" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "git reset buffer" })
-- map("n", "<leader>bl", "<cmd>Gitsigns blame_line<cr>", { desc = "git blame line" })

local function center_hunk()
  -- vim.defer_fn(function()
  -- end, 10)
  if popup.is_open "hunk" then
    popup.close "hunk"
  end
  gitsigns.preview_hunk()
  vim.cmd "normal! zz"
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
