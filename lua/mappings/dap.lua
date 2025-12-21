local map = require "mappings.map"

local dap = require "dap"
local dapui = require "dapui"
local trouble = require "trouble"

-- debugger
map("n", "<leader>dd", function()
  dap.continue()
end, { desc = "debug continue" })

map("n", "<A-n>", function()
  dap.continue()
end, { desc = "debug continue" })

map("n", "<leader>dp", function()
  dap.pause()
end, { desc = "debug pause" })

map("n", "<leader>dk", function()
  dap.terminate()
end, { desc = "debug kill" })

map("n", "<leader>dr", function()
  dap.restart_frame()
end, { desc = "debug restart current frame" })

map("n", "<leader>do", function()
  dap.step_over()
end, { desc = "debug step over" })

map("n", "<leader>di", function()
  dap.step_into()
end, { desc = "debug step into" })

map("n", "<leader>out", function()
  dap.step_out()
end, { desc = "debug step out" })

map("n", "<leader>b", function()
  dap.toggle_breakpoint()
end, { desc = "debug toggle breakpoint" })

-- open Dap UI automatically when debug starts
dap.listeners.before.attach.dapui_config = function()
  vim.cmd "Neotree close"
  trouble.close()
  dapui.open()
  _G.bottom_component_callback_close()
  vim.g.dapui_state_is_opened = true
end

dap.listeners.before.launch.dapui_config = function()
  vim.cmd "Neotree close"
  trouble.close()
  dapui.open()
  _G.bottom_component_callback_close()
  vim.g.dapui_state_is_opened = true
end

-- debug evaluation
map({ "n", "v" }, "<leader>dec", function()
  dapui.eval()
end, { desc = "debug evaluate on caret" })

map({ "n", "v" }, "<A-x>", function()
  dapui.eval()
end, { desc = "debug evaluate on caret" })

map("n", "<leader>dei", function()
  dapui.eval(vim.fn.input "Expression to evaluate: ")
end, { desc = "debug evaluate input" })

map("n", "<A-X>", function()
  dapui.eval(vim.fn.input "Expression to evaluate: ")
end, { desc = "debug evaluate input" })
