local map = require("mappings.map")
map("v", "/", function()
  vim.cmd "nohlsearch"
  -- send esc key so selection will be handled properly
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  vim.fn.feedkeys("/\\%V", "n")
end, { desc = "Search in visual selection" })

-- map("n", "<leader>rr", function()
--   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":%s///g<Left><Left>", true, false, true), "n", false)
--   vim.cmd "nohlsearch"
-- end, { desc = "Substitute in entire file" })

map("n", "<leader>ri", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gv:s///g<Left><Left>", true, false, true), "n", false)
  vim.cmd "nohlsearch"
end, { desc = "Substitute in selection" })
