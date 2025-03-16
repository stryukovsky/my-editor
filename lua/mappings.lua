require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local unset = vim.keymap.del
local dap, dapui = require "dap", require "dapui"
local term = require "nvchad.term"
local telescope_builtin = require "telescope.builtin"
local neoscroll = require "neoscroll"
-- unset nvchad shortcuts
unset({ "n"}, "<leader>h")
unset({ "n"}, "<leader>v")

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
map({ "n", "v" }, "<A-Up>", function() neoscroll.scroll(-0.1, { move_cursor=true; duration = 70 }) end)
map({ "n", "v" }, "<A-Down>", function() neoscroll.scroll(0.1, { move_cursor=true; duration = 70 }) end)

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

dapui.setup {
  controls = {
    element = "repl",
    enabled = true,
    icons = {
      disconnect = "",
      pause = "",
      play = "",
      run_last = "",
      step_back = "",
      step_into = "",
      step_out = "",
      step_over = "",
      terminate = "",
    },
  },
  element_mappings = {},
  expand_lines = true,
  floating = {
    border = "single",
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  force_buffers = true,
  icons = {
    collapsed = "",
    current_frame = "",
    expanded = "",
  },
  layouts = {
    {
      elements = {
        {
          id = "scopes",
          size = 0.40,
        },
        {
          id = "stacks",
          size = 0.35,
        },
        {
          id = "breakpoints",
          size = 0.25,
        },
        -- {
        --   id = "watches",
        --   size = 0.25,
        --   enabled = false
        -- },
      },
      position = "left",
      size = 40,
    },
    {
      elements = {
        -- {
        --   id = "repl",
        --   size = 0.5,
        -- },
        {
          id = "repl",
          size = 1,
        },
      },
      position = "bottom",
      size = 15,
    },
  },
  mappings = {
    edit = "e",
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    repl = "r",
    toggle = "t",
  },
  render = {
    indent = 1,
    max_value_lines = 100,
  },
}

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
