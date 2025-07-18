local map = require "mappings.map"
local neoscroll = require "neoscroll"

-- toggle numbering
local is_relative = false
map("n", "<A-1>", function()
  if vim.api.nvim_get_option_value("buftype", { buf = vim.fn.bufnr() }) == "" then
    is_relative = not is_relative
    if is_relative then
      vim.opt.number = true
      vim.opt.relativenumber = false
    else
      vim.opt.number = true
      vim.opt.relativenumber = true
    end
  end
end, { desc = "Navigation toggle relative numbering" })

map("n", "<A-v>", function()
  vim.g.enabled_virtual_lines = not vim.g.enabled_virtual_lines
  vim.diagnostic.config { virtual_lines = vim.g.enabled_virtual_lines }
end, { desc = "Navigation toggle virtual diagnostics" })

-- tabs navigation
map("n", "<A-,>", "<CMD>BufferPrevious<CR>", { desc = "Navigation prev buffer" })
map("n", "<A-<>", "<CMD>BufferPrevious<CR>", { desc = "Navigation prev buffer" })
map("n", "<A->>", "<CMD>BufferNext<CR>", { desc = "Navigation next buffer" })
map("n", "<A-.>", "<CMD>BufferNext<CR>", { desc = "Navigation next buffer" })
map("n", "<leader>x", "<CMD>BufferClose<CR>", { desc = "Navigation close buffer" })
map("n", "<leader>X", "<CMD>BufferCloseAllButCurrent<CR>", { desc = "Navigation close other buffers" })

map("n", "<leader>,", "<CMD>BufferMovePrevious<CR>", { desc = "Navigation move buffer left" })
map("n", "<leader>.", "<CMD>BufferMoveNext<CR>", { desc = "Navigation move buffer right" })
map("n", "<leader>pin", "<CMD>BufferPin<CR>", { desc = "Navigation pin buffer" })
-- navigate in jumps
map("n", "<A-[>", "<cmd>pop<cr>", { desc = "Navigation jump prev" })
map("n", "<A-]>", "<cmd>tag<cr>", { desc = "Navigation jump next" })

-- navigate in code
map({ "n", "v" }, "<C-u>", function()
  neoscroll.scroll(-0.2, { move_cursor = true, duration = 120 })
end)
map({ "n", "v" }, "<C-d>", function()
  neoscroll.scroll(0.2, { move_cursor = true, duration = 120 })
end)

-- format file, linter etc
map("n", "<leader>fm", function()
  require("conform").format({ lsp_fallback = true, async = true }, function(err, did_edit)
    if did_edit then
      vim.cmd "w"
    end
  end)
end, { desc = "File format file" })

-- block of code moving
map("n", "<C-H>", "<Plug>GoNSMLeft", {})
map("n", "<C-J>", "<Plug>GoNSMDown", {})
map("n", "<C-K>", "<Plug>GoNSMUp", {})
map("n", "<C-L>", "<Plug>GoNSMRight", {})

map("x", "<C-H>", "<Plug>GoVSMLeft", {})
map("x", "<C-J>", "<Plug>GoVSMDown", {})
map("x", "<C-K>", "<Plug>GoVSMUp", {})
map("x", "<C-L>", "<Plug>GoVSMRight", {})
