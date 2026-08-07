local map = require "mappings.map"
local is_normal_buffer = require "utils.is_normal_buffer"
local is_codediff_tab = require "utils.is_codediff_tab"
local notify = require "configs.notify"

local function toggle_wrap()
  vim.wo.wrap = not vim.wo.wrap
  local msg = vim.wo.wrap and "Wrap is toggled on" or "Wrap is toggled off"
  notify.replace("navigation.wrap", "Navigation", msg, vim.log.levels.INFO)
end
map("n", "<A-W>", toggle_wrap, { desc = "Navigation toggle wrap in window" })
map("n", "<A-r>", toggle_wrap, { desc = "Navigation toggle wrap in window" })

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
    local msg = "Relative line numbering"
    if not is_relative then
      msg = "Absolute line numbering"
    end
    notify.replace("navigation.numbering", "Navigation", msg, vim.log.levels.INFO)
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
    notify.replace("navigation.virtual_lines", "Navigation", "Virtual lines disabled", vim.log.levels.INFO)
    return
  end
  vim.diagnostic.config {
    virtual_lines = {
      severity = {
        min = vim.diagnostic.severity[virtual_lines_diagnostic_counter],
      },
    },
  }

  local msg = "Virtual lines enabled: " .. vim.diagnostic.severity[virtual_lines_diagnostic_counter]
  notify.replace("navigation.virtual_lines", "Navigation", msg, vim.log.levels.INFO)
end, { desc = "Navigation filter virtual diagnostics" })

local function construct_handler(cmd)
  return function()
    if is_codediff_tab() then
      notify.send("Navigation", "Cannot open: CodeDiff is current tabpage", vim.log.levels.ERROR)
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
      notify.send("Conform", err, vim.log.levels.ERROR)
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

map("n", "zZ", "zszH", { desc = "Center cursor horizontally" })
