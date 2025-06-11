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
map("n", "<Tab>", "<plug>(CybuLastusedNext)", { desc = "Navigation next used buffer" })
map("n", "<S-Tab>", "<plug>(CybuLastusedPrev)", { desc = "Navigation prev used buffer" })

map("n", "<A-Left>","<CMD>BufferPrevious<CR>",{ desc = "Navigation prev buffer" })
map("n", "<A-Right>", "<CMD>BufferNext<CR>",{ desc = "Navigation next buffer" })
map("n", "<leader>x", "<CMD>BufferClose<CR>", { desc = "Navigation close buffer" })
map("n", "<leader>X", "<CMD>BufferCloseAllButCurrent<CR>", { desc = "Navigation close other buffers" })

map("n", "<leader><Left>", "<CMD>BufferMovePrevious<CR>", { desc = "Navigation move buffer left" })
map("n", "<leader><Right>", "<CMD>BufferMoveNext<CR>", { desc = "Navigation move buffer right" })
map("n", "<leader>pin", "<CMD>BufferPin<CR>", { desc = "Navigation pin buffer" })
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
