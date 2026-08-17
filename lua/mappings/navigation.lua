local map = require "mappings.map"
local is_normal_buffer = require "utils.is_normal_buffer"
local notify = require "configs.notify"

local function toggle_wrap()
  local enabled = not vim.wo.wrap
  vim.g.wrap = enabled
  vim.wo.wrap = enabled
  vim.wo.linebreak = enabled
  vim.wo.breakindent = false
  local msg = enabled and "Wrap is toggled on" or "Wrap is toggled off"
  notify.replace("navigation.wrap", "Navigation", msg, vim.log.levels.INFO)
end
map("n", "<A-W>", toggle_wrap, { desc = "Navigation toggle wrap in window" })
map("n", "<A-r>", toggle_wrap, { desc = "Navigation toggle wrap in window" })

-- toggle numbering
map("n", "<A-1>", function()
  if is_normal_buffer() then
    local relative = not vim.opt.relativenumber:get()
    vim.opt.number = true
    vim.opt.relativenumber = relative
    local msg = relative and "Relative line numbering" or "Absolute line numbering"
    notify.replace("navigation.numbering", "Navigation", msg, vim.log.levels.INFO)
  end
end, { desc = "Navigation toggle relative numbering" })

map("n", "<A-G>", function()
  vim.g.grammar_strict = not vim.g.grammar_strict
  require("configs.strict_grammar").apply_spellbad()
  local msg = vim.g.grammar_strict and "Grammar-strict on" or "Grammar-strict off"
  notify.replace("spell.grammar_strict", "Spell", msg, vim.log.levels.INFO)
end, { desc = "Toggle grammar-strict spell highlight" })

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
    vim.cmd(cmd)
  end
end
-- buffer navigation
map({ "n" }, "<A-,>", construct_handler "BufferPrevious", { desc = "Navigation prev buffer" })
map({ "n" }, "<A-.>", construct_handler "BufferNext", { desc = "Navigation next buffer" })

-- tab navigation
-- `<A->>` is not a valid keycode (`>` closes the notation). `>` / `<` are Shift+`.` / `,`.
map({ "n" }, "<A-<>", "<cmd>tabprevious<CR>", { desc = "Navigation prev tab" })
map({ "n" }, "<A-S-,>", "<cmd>tabprevious<CR>", { desc = "Navigation prev tab" })
map({ "n" }, "<A-S-.>", "<cmd>tabnext<CR>", { desc = "Navigation next tab" })
map("n", "<leader>tab", function()
  vim.cmd.tabnew()
  require("configs.dashboard").open_in(0, { isolate = true })
end, { desc = "Navigation new tab" })
map("n", "<leader>x", construct_handler "BufferClose!", { desc = "Navigation close buffer" })
map("n", "<leader>X", construct_handler "silent BufferCloseAllButCurrentOrPinned", { desc = "Navigation close other buffers" })
map("n", "<leader>,", construct_handler "BufferMovePrevious", { desc = "Navigation move buffer left" })
map("n", "<leader>.", construct_handler "BufferMoveNext", { desc = "Navigation move buffer right" })
map("n", "<leader><", construct_handler "BufferMovePrevious", { desc = "Navigation move buffer left" })
map("n", "<leader>>", construct_handler "BufferMoveNext", { desc = "Navigation move buffer right" })

map("n", "<A-space>", construct_handler "BufferPick", { desc = "Pick buffer" })
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
