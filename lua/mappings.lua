require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

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
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "toggle terminal" })

-- toggle nvimtree
map({ "n", "t" }, "<A-e>", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

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

local dap, dapui = require "dap", require "dapui"
dapui.setup()

-- open Dap UI automatically when debug starts
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end

-- close Dap UI with :DapCloseUI
vim.keymap.set("n", "<leader>dw", function()
  require("dapui").toggle()
end, { desc = "debug toggle view" })

-- debug evaluation
vim.keymap.set({ "n", "v" }, "<leader>de", function()
  require("dapui").eval()
end, { desc = "debug evaluate on caret" })

vim.keymap.set("n", "<leader>dee", function()
  require("dapui").eval(vim.fn.input "Expression to evaluate: ")
end, { desc = "debug evaluate input" })
