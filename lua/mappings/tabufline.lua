local map = require "mappings.map"
local neoscroll = require "neoscroll"

-- tabs navigation
map("n", "<leader><Right>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<leader><Left>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

map("n", "<tab>", function()
  require("nvchad.tabufline").next()
end, { desc = "buffer goto next" })

map("n", "<S-tab>", function()
  require("nvchad.tabufline").prev()
end, { desc = "buffer goto prev" })

-- navigate in jumps
map("n", "<A-[>", "<cmd>pop<cr>", { desc = "jump prev" })
map("n", "<A-]>", "<cmd>tag<cr>", { desc = "jump next" })

-- navigate in code
map({ "n", "v" }, "<A-Left>", "b")
map({ "n", "v" }, "<A-Right>", "w")
map({ "n", "v" }, "<A-Up>", function()
  neoscroll.scroll(-0.2, { move_cursor = true, duration = 120 })
end)
map({ "n", "v" }, "<A-Down>", function()
  neoscroll.scroll(0.2, { move_cursor = true, duration = 120 })
end)

-- save
map("n", "<leader>s", ":w<cr>", { desc = "save file" })

-- close current tab
map("n", "<leader>w", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "close current buffer" })

-- close others
map("n", "<leader>W", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "close other buffers" })

-- format file, linter etc
map("n", "<leader>fm", function()
  require("conform").format({ lsp_fallback = true, async = true }, function(err, did_edit)
    if did_edit then
      vim.cmd "w"
    end
  end)
end, { desc = "general format file" })

-- block of code moving
map("n", "<S-Left>", "<Plug>GoNSMLeft", {})
map("n", "<S-Down>", "<Plug>GoNSMDown", {})
map("n", "<S-Up>", "<Plug>GoNSMUp", {})
map("n", "<S-Right>", "<Plug>GoNSMRight", {})

map("x", "<S-Left>", "<Plug>GoVSMLeft", {})
map("x", "<S-Down>", "<Plug>GoVSMDown", {})
map("x", "<S-Up>", "<Plug>GoVSMUp", {})
map("x", "<S-Right>", "<Plug>GoVSMRight", {})
