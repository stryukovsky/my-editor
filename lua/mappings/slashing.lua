local map = require "mappings.map"
local navigation_repeat = require "utils.navigation_repeat"
local slashing = require "configs.slashing"

local function leave_visual()
  vim.cmd "nohlsearch"
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
end

map("n", "/", function()
  require("searchbox").incsearch()
end, { desc = "Search forward" })

map("n", "<A-q>", function()
  require("searchbox").incsearch()
end, { desc = "Search forward" })

map("n", "<A-Q>", function()
  require("searchbox").incsearch { reverse = true, title = " Search back " }
end, { desc = "Search backward" })

map("v", "/", function()
  leave_visual()
  vim.schedule(function()
    require("searchbox").incsearch {
      visual_mode = true,
      title = " Search in selection ",
    }
  end)
end, { desc = "Search in visual selection" })

map("v", "<A-q>", function()
  leave_visual()
  vim.schedule(function()
    require("searchbox").incsearch {
      visual_mode = true,
      title = " Search in selection ",
    }
  end)
end, { desc = "Search in visual selection" })

map({ "n", "x" }, "n", navigation_repeat.repeat_next, { desc = "Repeat next navigation" })
map({ "n", "x" }, "N", navigation_repeat.repeat_previous, { desc = "Repeat previous navigation" })

map("n", "*", function()
  if slashing.jump "*" then
    slashing.activate()
  end
end, { desc = "Search word forward" })

map("n", "g*", function()
  if slashing.jump "g*" then
    slashing.activate()
  end
end, { desc = "Search word forward (no bounds)" })

map("n", "g#", function()
  if slashing.jump "g#" then
    slashing.activate()
  end
end, { desc = "Search word backward (no bounds)" })

-- map("n", "<leader>rr", function()
--   vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(":%s///g<Left><Left>", true, false, true), "n", false)
--   vim.cmd "nohlsearch"
-- end, { desc = "Substitute in entire file" })

map("n", "<leader>ri", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gv:s///g<Left><Left>", true, false, true), "n", false)
  vim.cmd "nohlsearch"
end, { desc = "Substitute in selection" })

map("v", "<leader>ri", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", false)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gv:s///g<Left><Left>", true, false, true), "n", false)
  vim.cmd "nohlsearch"
end, { desc = "Substitute in selection" })
