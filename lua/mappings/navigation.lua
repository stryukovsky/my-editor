local map = require "mappings.map"

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

local virtual_lines_diagnostic_counter = 4

map("n", "<A-v>", function()
  virtual_lines_diagnostic_counter = virtual_lines_diagnostic_counter - 1
  if virtual_lines_diagnostic_counter == 0 then
    vim.g.enabled_virtual_lines = false
    virtual_lines_diagnostic_counter = 5
    vim.diagnostic.config {
      virtual_lines = false,
    }
    vim.print "Virtual lines disabled"
    return
  end
  vim.diagnostic.config {
    virtual_lines = {
      severity = {
        min = vim.diagnostic.severity[virtual_lines_diagnostic_counter],
      },
    },
  }

  vim.print("Virtual lines enabled: " .. vim.diagnostic.severity[virtual_lines_diagnostic_counter])
end, { desc = "Navigation filter virtual diagnostics" })

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

-- format file, linter etc
map("n", "<leader>fm", function()
  require("conform").format({ lsp_fallback = true, async = true }, function(err, did_edit)
    if err then
      vim.print(err)
    end
    vim.defer_fn(function()
      if did_edit then
        vim.cmd "silent! w"
      end
    end, 100)
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
