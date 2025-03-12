require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set
local dap, dapui = require "dap", require "dapui"
local term = require "nvchad.term"
-- tabs navigation
map("n", "<leader><Left>", ":bprev<cr>", { desc = "previous buffer" })
map("n", "<leader><Right>", ":bnext<cr>", { desc = "next buffer" })

-- navigate in code
map("n", "<A-Left>", "b")
map("n", "<A-Right>", "w")
map("n", "<A-Up>", "5k")
map("n", "<A-Down>", "5j")

-- save
map("n", "<leader>s", ":w<cr>", { desc = "save file" })

-- toggle terminal
map({ "n", "t" }, "<A-t>", function()
  term.toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "toggle terminal" })

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
map("n", "<leader>gg", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>k", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })

-- search and replace
map("n", "<leader>F", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })

map("n", "<leader>r", function()
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
  local intervalStr = tostring(vim.fn.input "Input two numbers of lines interval: ")
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
vim.keymap.set("n", "<leader>dc", function()
  require("dap").continue()
end, { desc = "debug continue" })

vim.keymap.set("n", "<leader>do", function()
  require("dap").step_over()
end, { desc = "debug step over" })

vim.keymap.set("n", "<leader>di", function()
  require("dap").step_into()
end, { desc = "debug step into" })

vim.keymap.set("n", "<leader>out", function()
  require("dap").step_out()
end, { desc = "debug step out" })

vim.keymap.set("n", "<leader>b", function()
  require("dap").toggle_breakpoint()
end, { desc = "debug toggle breakpoint" })

dapui.setup {
  controls = {
    element = "console",
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
          id = "console",
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
vim.keymap.set("n", "<leader>dw", function()
  dapui.close()
  vim.cmd "NvimTreeOpen"
end, { desc = "debug close view" })

vim.keymap.set("n", "<leader>dd", function()
  dapui.open()
  vim.cmd "NvimTreeClose"
end, { desc = "debug close view" })

-- debug evaluation
vim.keymap.set({ "n", "v" }, "<leader>de", function()
  dapui.eval()
end, { desc = "debug evaluate on caret" })

vim.keymap.set("n", "<leader>dee", function()
  dapui.eval(vim.fn.input "Expression to evaluate: ")
end, { desc = "debug evaluate input" })
