require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local unset = vim.keymap.del
local dap, dapui = require "dap", require "dapui"
local term = require "nvchad.term"
local telescope_builtin = require "telescope.builtin"
local neoscroll = require "neoscroll"
local telescope = require "telescope"
-- unset nvchad shortcuts
unset({ "n" }, "<leader>h")
unset({ "n" }, "<leader>v")
unset({ "n" }, "<C-s>")
unset({ "n" }, "<C-w>")

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
  neoscroll.scroll(-0.1, { move_cursor = true, duration = 70 })
end)
map({ "n", "v" }, "<A-Down>", function()
  neoscroll.scroll(0.1, { move_cursor = true, duration = 70 })
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

telescope.setup {
  extensions = {
    undo = {
      mappings = {
        i = {
          ["<C-cr>"] = require("telescope-undo.actions").yank_additions,
          ["<S-cr>"] = require("telescope-undo.actions").yank_deletions,
          ["<cr>"] = require("telescope-undo.actions").restore,
          -- alternative defaults, for users whose terminals do questionable things with modified <cr>
          ["<C-y>"] = require("telescope-undo.actions").yank_deletions,
          ["<C-r>"] = require("telescope-undo.actions").restore,
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
