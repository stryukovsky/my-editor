local map = require "mappings.map"
local is_normal_buffer = require "utils.is_normal_buffer"
local is_codediff_tab = require "utils.is_codediff_tab"

-- toggle numbering
local is_relative = false
map("n", "<A-1>", function()
  if is_normal_buffer() then
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

local function construct_handler(cmd)
  return function()
    if is_codediff_tab() then
      vim.notify "Cannot open: CodeDiff is current tabpage"
      return
    end

    vim.cmd(cmd)
  end
end
-- tabs navigation
map({ "n" }, "<A-,>", construct_handler "BufferPrevious", { desc = "Navigation prev buffer" })
map({ "n" }, "<A-<>", construct_handler "BufferPrevious", { desc = "Navigation prev buffer" })
map({ "n" }, "<A->>", construct_handler "BufferNext", { desc = "Navigation next buffer" })
map({ "n" }, "<A-.>", construct_handler "BufferNext", { desc = "Navigation next buffer" })
map("n", "<leader>x", construct_handler "BufferClose!", { desc = "Navigation close buffer" })
map("n", "<leader>X", construct_handler "silent BufferCloseAllButCurrentOrPinned", { desc = "Navigation close other buffers" })
map("n", "<leader>,", construct_handler "BufferMovePrevious", { desc = "Navigation move buffer left" })
map("n", "<leader>.", construct_handler "BufferMoveNext", { desc = "Navigation move buffer right" })
map("n", "<leader><", construct_handler "BufferMovePrevious", { desc = "Navigation move buffer left" })
map("n", "<leader>>", construct_handler "BufferMoveNext", { desc = "Navigation move buffer right" })

map("n", "<A-h>", construct_handler "BufferPick", { desc = "Pick buffer" })
map("n", "<leader>pin", construct_handler "BufferPin", { desc = "Navigation pin buffer" })

-- navigate in jumps
map("n", "<A-[>", "<cmd>pop<cr>", { desc = "Navigation jump prev" })
map("n", "<A-]>", "<cmd>tag<cr>", { desc = "Navigation jump next" })

map({ "n", "v" }, "<leader>fm", function()
  require("conform").format({ lsp_fallback = true, async = true }, function(err, _did_edit)
    if err then
      vim.print(err)
    else
      vim.defer_fn(function()
        vim.cmd "silent! w"
      end, 100)
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
