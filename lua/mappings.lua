require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local unset = vim.keymap.del
local dap, dapui = require "dap", require "dapui"
local telescope_builtin = require "telescope.builtin"
local neoscroll = require "neoscroll"
local telescope = require "telescope"
local mc = require "multicursor-nvim"

-- unset nvchad shortcuts
unset({ "n" }, "<leader>h")
unset({ "n" }, "<leader>v")
unset({ "n" }, "<C-s>")
unset({ "n" }, "<C-w>")

-- terminal 
--
map({ "n", "t" }, "<A-t>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

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

-- toggle terminal
-- map({ "n", "t" }, "<A-t>", function()
--   term.toggle { pos = "sp", id = "htoggleTerm" }
-- end, { desc = "toggle terminal" })
--
-- toggle nvimtree
map({ "n", "t" }, "<A-e>", function()
  dapui.close()
  vim.cmd "NvimTreeFocus"
end, { desc = "nvimtree focus window" })

-- close current tab
map("n", "<leader>w", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "close current buffer" })

-- close others
map("n", "<leader>ww", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "close other buffers" })

-- show git history
map("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<CR>", { desc = "telescope git branches" })
map("n", "<leader>k", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })

-- search and replace
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope search contents (grep)" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

map("n", "<leader>rr", function()
  local toReplace = tostring(vim.fn.input "Input string to replace: ")
  if toReplace == "" then
    print ""
    return
  end
  local replaceWith = tostring(vim.fn.input "Input new string: ")
  if replaceWith == "" then
    print ""
    return
  end
  vim.cmd("%s/" .. toReplace .. "/" .. replaceWith)
end, { desc = "replace in file" })

map("n", "<leader>ri", function()
  local toReplace = tostring(vim.fn.input "[Interval] Input string to replace: ")
  if toReplace == "" then
    print ""
    return
  end
  local replaceWith = tostring(vim.fn.input "[Interval] Input new string: ")
  if replaceWith == "" then
    print ""
    return
  end
  local intervalStr = tostring(vim.fn.input "[Interval] Input two numbers of lines interval: ")
  local numbers = {}
  local numbersCount = 0
  for number in string.gmatch(intervalStr, "%d+") do
    numbers[#numbers + 1] = tonumber(number + 0)
    numbersCount = numbersCount + 1
  end
  if numbersCount == 2 then
    vim.cmd(tostring(numbers[1]) .. "," .. tostring(numbers[2]) .. "s/" .. toReplace .. "/" .. replaceWith .. "/g")
  else
    print "Expected exactly two numbers"
  end
end, { desc = "replace in file" })

-- format file, linter etc
map("n", "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

-- debugger
map("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "debug continue" })

map("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "debug step over" })

map("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "debug step into" })

map("n", "<leader>out", function()
  require("dap").step_out()
end, { desc = "debug step out" })

map("n", "<leader>b", function()
  require("dap").toggle_breakpoint()
end, { desc = "debug toggle breakpoint" })

-- open Dap UI automatically when debug starts
dap.listeners.before.attach.dapui_config = function()
  vim.cmd "NvimTreeClose"
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  vim.cmd "NvimTreeClose"
  dapui.open()
end

-- close Dap UI with :DapCloseUI
map("n", "<leader>dw", function()
  dapui.close()
  vim.cmd "NvimTreeOpen"
end, { desc = "debug close view" })

map("n", "<leader>dd", function()
  dapui.open()
  vim.cmd "NvimTreeClose"
end, { desc = "debug open view" })

-- debug evaluation
map({ "n", "v" }, "<leader>dec", function()
  dapui.eval()
end, { desc = "debug evaluate on caret" })

map("n", "<leader>dei", function()
  dapui.eval(vim.fn.input "Expression to evaluate: ")
end, { desc = "debug evaluate input" })

-- lsp interactions

map("n", "<leader>lr", function()
  telescope_builtin.lsp_references {}
end, { desc = "lsp references (usages)" })

map("n", "<leader>ltd", function()
  telescope_builtin.lsp_type_definitions {}
end, { desc = "lsp type definitions" })

map("n", "<leader>li", function()
  telescope_builtin.lsp_implementations {}
end, { desc = "lsp implementations" })

map("n", "<leader>ld", function()
  telescope_builtin.lsp_definitions {}
end, { desc = "lsp definitions" })

map("n", "<leader>lci", function()
  telescope_builtin.lsp_incoming_calls {}
end, { desc = "lsp show incoming calls" })

map("n", "<leader>lco", function()
  telescope_builtin.lsp_outgoing_calls {}
end, { desc = "lsp show outcoming calls" })

map("n", "<leader>lp", function()
  telescope_builtin.diagnostics { bufnr = 0 }
end, { desc = "lsp inspections on current buffer" })

map("n", "<leader>lP", function()
  telescope_builtin.diagnostics {}
end, { desc = "lsp inspections on all" })

-- block of code moving
map("n", "<S-Left>", "<Plug>GoNSMLeft", {})
map("n", "<S-Down>", "<Plug>GoNSMDown", {})
map("n", "<S-Up>", "<Plug>GoNSMUp", {})
map("n", "<S-Right>", "<Plug>GoNSMRight", {})

map("x", "<S-Left>", "<Plug>GoVSMLeft", {})
map("x", "<S-Down>", "<Plug>GoVSMDown", {})
map("x", "<S-Up>", "<Plug>GoVSMUp", {})
map("x", "<S-Right>", "<Plug>GoVSMRight", {})

-- windows focus move
map({ "n", "v", "t" }, "<A-a>", "<C-W>h", { desc = "switch window left" })
map({ "n", "v", "t" }, "<A-d>", "<C-W>l", { desc = "switch window right" })
map({ "n", "v", "t" }, "<A-s>", "<C-W>j", { desc = "switch window down" })
map({ "n", "v", "t" }, "<A-w>", "<C-W>k", { desc = "switch window up" })

map({ "n", "v", "t" }, "+", "<C-W>3>", { desc = "increase window width" })
map({ "n", "v", "t" }, "_", "<C-W>3<", { desc = "decrease window width" })

-- telescope extensions
-- undo
map("n", "<leader>u", function()
  telescope.extensions.undo.undo()
end)

require("telescope").setup {
  extensions = {
    undo = {
      mappings = {
        i = {
          ["<A-y>"] = require("telescope-undo.actions").yank_additions,
          ["<A-Y>"] = require("telescope-undo.actions").yank_deletions,
          ["<A-r>"] = require("telescope-undo.actions").restore,
        },
        n = {
          ["y"] = require("telescope-undo.actions").yank_additions,
          ["Y"] = require("telescope-undo.actions").yank_deletions,
          ["u"] = require("telescope-undo.actions").restore,
        },
      },
    },
  },
}

-- gitsigns
map("n", "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", { desc = "git hunk reset" })
map("n", "<leader>gs", "<cmd>Gitsigns select_hunk<cr>", { desc = "git hunk select" })
map("n", "<leader>gp", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "git hunk preview" })

map("n", "<leader>gs", "<cmd>Gitsigns stage_buffer<cr>", { desc = "git stage buffer" })
map("n", "<leader>gR", "<cmd>Gitsigns reset_buffer<cr>", { desc = "git reset buffer" })
map("n", "<leader>gB", "<cmd>Gitsigns blame<cr>", { desc = "git blame buffer" })
map("n", "<leader>bl", "<cmd>Gitsigns blame_line<cr>", { desc = "git blame line" })

map("n", "g<Down>", "<cmd>Gitsigns next_hunk<cr>", { desc = "git next hunk" })
map("n", "g<Up>", "<cmd>Gitsigns prev_hunk<cr>", { desc = "git prev hunk" })
map("n", "<leader>gC", function()
  local message = tostring(vim.fn.input "Input commit message: ")
  if message == "" then
    print ""
    return
  end
  vim.fn.system('git commit -m "' .. message .. '"')
  print ""
end, { desc = "git commit staged" })

map("n", "<leader>gP", function()
  local response = vim.fn.system "git push --set-upstream origin $(git rev-parse --abbrev-ref HEAD) "
  print(response)
end, { desc = "git push" })

map("n", "<leader>gS", function()
  vim.fn.system "git add ."
end, { desc = "git stage all changes" })

-- nvimtree
map("n", "<leader>a", "<cmd>NvimTreeFindFile<cr>", { desc = "nvimtree find current file" })

-- multi cursor
-- Add or skip cursor above/below the main cursor.
map({ "n", "x" }, "<S-A-Up>", function()
  mc.lineAddCursor(-1)
end)

map({ "n", "x" }, "<S-A-Down>", function()
  mc.lineAddCursor(1)
end)

-- Add or skip adding a new cursor by matching word/selection
map({ "n", "x" }, "<S-A-Right>", function()
  mc.matchAddCursor(1)
end)
map({ "n", "x" }, "<S-A-Left>", function()
  mc.matchAddCursor(-1)
end)

-- Add and remove cursors with control + left click.
map("n", "<c-leftmouse>", mc.handleMouse)
map("n", "<c-leftdrag>", mc.handleMouseDrag)
map("n", "<c-leftrelease>", mc.handleMouseRelease)

-- Disable and enable cursors.
map({ "n", "x" }, "<c-q>", mc.toggleCursor)

-- Mappings defined in a keymap layer only apply when there are
-- multiple cursors. This lets you have overlapping mappings.
mc.addKeymapLayer(function(layerSet)
  -- Select a different cursor as the main one.
  layerSet({ "n", "x" }, "<S-Up>", mc.prevCursor)
  layerSet({ "n", "x" }, "<S-Down>", mc.nextCursor)

  -- Delete the main cursor.
  layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)

  -- Enable and clear cursors using escape.
  layerSet("n", "<esc>", function()
    if not mc.cursorsEnabled() then
      mc.enableCursors()
    else
      mc.clearCursors()
    end
  end)
end)

-- nvim-cmp

local cmp = require("cmp")
local luasnip = require("luasnip")
-- cmp.setup{
--       mapping = cmp.mapping.preset.insert({
--       ['<C-Down>'] = cmp.mapping.scroll_docs(-4),
--       ['<C-Up>'] = cmp.mapping.scroll_docs(4),
--       ['<C-Space>'] = cmp.mapping.complete(),
--       ['<C-e>'] = cmp.mapping.abort(),
--       ['<Down>'] = cmp.select_next_item,
--       ['<leader>o'] = cmp.select_prev_item,
--      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
--     }),
-- }
--
--
local nvim_cmp_next = function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end

local nvim_cmp_prev = function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end

cmp.setup.global {
  mapping = cmp.mapping.preset.insert({
		["<Down>"] = cmp.mapping(nvim_cmp_next, { 'i' }),
		["<Up>"] = cmp.mapping(nvim_cmp_prev, { 'i' }),
  })
}

cmp.setup.cmdline(':', {
  mapping = cmp.mapping.preset.cmdline({
		["<Down>"] = cmp.mapping(nvim_cmp_next, { 'c' }),
		["<Up>"] = cmp.mapping(nvim_cmp_prev, { 'c' }),
  })
})
