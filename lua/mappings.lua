require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

-- tabs navigation
map("n", "<leader><Left>", ":bprev<cr>")
map("n", "<leader><Right>", ":bnext<cr>")


-- navigate in code
map("n", "<A-Left>", "b")
map("n", "<A-Right>", "w")

-- save
map("n", "<leader>s", ":w<cr>")

-- toggle terminal
map({ "n", "t" }, "<A-t>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

-- toggle nvimtree 
map({"n", "t"}, "<A-e>", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })

-- close current tab
map("n", "<leader>w", function()
  require("nvchad.tabufline").close_buffer()
end, { desc = "buffer close" })

-- close others
map("n", "<leader>ww", function()
  require("nvchad.tabufline").closeAllBufs(false)
end, { desc = "buffer close" })

-- show git history
map("n", "<leader>gg", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>k", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })

-- search and replace
map("n", "<leader>F", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })

-- format file, linter etc
map("n", "<leader>l", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })

-- debugger
vim.keymap.set("n", "<F5>", function()
  require("dap").continue()
end)
vim.keymap.set("n", "<F10>", function()
  require("dap").step_over()
end)
vim.keymap.set("n", "<F11>", function()
  require("dap").step_into()
end)
vim.keymap.set("n", "<F12>", function()
  require("dap").step_out()
end)
vim.keymap.set("n", "<leader>b", function()
  require("dap").toggle_breakpoint()
end)

local dap, dapui = require "dap", require "dapui"
dapui.setup()

-- open Dap UI automatically when debug starts (e.g. after <F5>)
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end

-- close Dap UI with :DapCloseUI
vim.keymap.set("n", "<leader>dw", function()
  require("dapui").close()
end)

-- use <Alt-e> to eval expressions
vim.keymap.set({ "n", "v" }, "<leader>d", function()
  require("dapui").eval()
end)
