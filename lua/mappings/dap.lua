local map = require "mappings.map"

local dap = require "dap"
local dapui = require "dapui"

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
