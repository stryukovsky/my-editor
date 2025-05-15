local map = require "mappings.map"
local neoscroll = require "neoscroll"

-- toggle numbering

local is_relative = false
map("n", "<A-1>", function()
  if vim.api.nvim_get_option_value("buftype", { buf = vim.fn.bufnr() }) == "" then
    if is_relative then
      vim.cmd "set number norelativenumber"
    else
      vim.cmd "set relativenumber"
    end
    is_relative = not is_relative
  end
end, { desc = "Navigation toggle relative numbering" })

-- tabs navigation
map("n", "<leader><Right>", function()
  require("nvchad.tabufline").next()
end, { desc = "Navigation buffer goto next" })

map("n", "<leader><Left>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Navigation buffer goto prev" })

map("n", "<A-Right>", function()
  require("nvchad.tabufline").next()
end, { desc = "Navigation buffer goto next" })

map("n", "<A-Left>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Navigation buffer goto prev" })

map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "Navigation buffer goto next" })

map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "Navigation buffer goto prev" })

-- navigate in jumps
map("n", "<A-[>", "<cmd>pop<cr>", { desc = "Navigation jump prev" })
map("n", "<A-]>", "<cmd>tag<cr>", { desc = "Navigation jump next" })

-- navigate in code
map({ "n", "v" }, "<A-Up>", function()
  neoscroll.scroll(-0.2, { move_cursor = true, duration = 120 })
end)
map({ "n", "v" }, "<A-Down>", function()
  neoscroll.scroll(0.2, { move_cursor = true, duration = 120 })
end)

-- save

-- close current tab
map("n", "<leader>x", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "Navigation close current buffer" })

-- close others
map("n", "<leader>X", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "Navigation close other buffers" })

map("n", "<leader>s", ":w<cr>", { desc = "File save file" })
-- format file, linter etc
map("n", "<leader>fm", function()
  require("conform").format({ lsp_fallback = true, async = true }, function(err, did_edit)
    if did_edit then
      vim.cmd "w"
    end
  end)
end, { desc = "File format file" })

-- block of code moving
map("n", "<S-Left>", "<Plug>GoNSMLeft", {})
map("n", "<S-Down>", "<Plug>GoNSMDown", {})
map("n", "<S-Up>", "<Plug>GoNSMUp", {})
map("n", "<S-Right>", "<Plug>GoNSMRight", {})

map("x", "<S-Left>", "<Plug>GoVSMLeft", {})
map("x", "<S-Down>", "<Plug>GoVSMDown", {})
map("x", "<S-Up>", "<Plug>GoVSMUp", {})
map("x", "<S-Right>", "<Plug>GoVSMRight", {})
