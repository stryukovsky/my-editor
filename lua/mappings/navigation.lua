local map = require "mappings.map"
local is_normal_buffer = require "utils.is_normal_buffer"
local notify = require "configs.notify"
local ui_prevent_mess = require "utils.ui_prevent_mess"
local navigation_repeat = require "utils.navigation_repeat"

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
-- Zen-mode floats break on tab change; close conflicting UI first.
local function tab_cmd(cmd)
  return function()
    ui_prevent_mess()
    vim.cmd(cmd)
  end
end
map({ "n" }, "<A-<>", tab_cmd "tabprevious", { desc = "Navigation prev tab" })
map({ "n" }, "<A-S-,>", tab_cmd "tabprevious", { desc = "Navigation prev tab" })
map({ "n" }, "<A-S-.>", tab_cmd "tabnext", { desc = "Navigation next tab" })
-- <A-S-,> / <A-S-.> still walk Neovim tabs (leftover). New workspaces are Kitty tabs:
-- <leader>tab → kitten @ launch --type=tab (cwd inherited). Projects go through configs.projects.
map("n", "<leader>tab", function()
  require("configs.kitten").launch { type = "tab" }
end, { desc = "Navigation new kitty tab" })
map("n", "<leader>x", construct_handler "BufferClose!", { desc = "Navigation close buffer" })
map("n", "<leader>X", construct_handler "silent BufferCloseAllButCurrentOrPinned", { desc = "Navigation close other buffers" })
map("n", "<leader>,", construct_handler "BufferMovePrevious", { desc = "Navigation move buffer left" })
map("n", "<leader>.", construct_handler "BufferMoveNext", { desc = "Navigation move buffer right" })
map("n", "<leader><", construct_handler "BufferMovePrevious", { desc = "Navigation move buffer left" })
map("n", "<leader>>", construct_handler "BufferMoveNext", { desc = "Navigation move buffer right" })

map("n", "<A-space>", construct_handler "BufferPick", { desc = "Pick buffer" })
map("n", "<leader>pin", construct_handler "BufferPin", { desc = "Navigation pin buffer" })

local function goto_spell(direction)
  local motion = direction > 0 and "]s" or "[s"
  vim.cmd("normal! " .. vim.v.count1 .. motion)
end

map("n", "]s", function()
  navigation_repeat.run(function()
    goto_spell(1)
  end)
end, { desc = "Next spelling issue" })

map("n", "[s", function()
  navigation_repeat.run(function()
    goto_spell(-1)
  end)
end, { desc = "Prev spelling issue" })


map("n", "]]", navigation_repeat.repeat_last, { desc = "Repeat last navigation" })

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

map({ "x", "n" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "x", "n" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("n", "p", "P", { desc = "override paste" })

