---@diagnostic disable: duplicate-set-field
local map = require "mappings.map"
local widgets = require "dap.ui.widgets"
local dap = require "dap"
local debug_output = require("configs.debug_output")
-- local trouble = require "trouble"

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

local function widgets_mappings(toggling_mapping)
  vim.schedule(function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>q<CR>", {
      noremap = true,
      silent = true,
      nowait = true,
      desc = "Close buffer",
    })

    -- Handle both string and array
    local mappings = type(toggling_mapping) == "table" and toggling_mapping or { toggling_mapping }

    for _, mapping in ipairs(mappings) do
      vim.api.nvim_buf_set_keymap(bufnr, "n", mapping, "<cmd>q<CR>", {
        noremap = true,
        silent = true,
        nowait = true,
        desc = "Close buffer",
      })
    end
  end)
end

local widgets_common_title_part = " 'a' to see commands  '<CR>' to expand items  'q' to exit"
map("n", "<leader>dv", function()
  widgets.centered_float(widgets.scopes, { title = "  Variables " .. widgets_common_title_part })
  widgets_mappings "<leader>dv"
end, { desc = "debug variables" })

-- the same stuff lol
map("n", "<leader>ds", function()
  widgets.centered_float(widgets.scopes, { title = "  Scopes " .. widgets_common_title_part })
  widgets_mappings "<leader>ds"
end, { desc = "debug scopes" })

map("n", "<leader>df", function()
  widgets.centered_float(widgets.frames, { title = "  Frames " .. widgets_common_title_part })
  widgets_mappings "<leader>df"
end, { desc = "debug frames" })

map("n", "<leader>dl", function()
  debug_output()
end, { desc = "debug show process log" })

map("n", "<leader>dt", function()
  widgets.centered_float(widgets.threads, { title = "  Threads " .. widgets_common_title_part })
  widgets_mappings "<leader>dt"
end, { desc = "debug threads" })

-- debug evaluation
map({ "n", "v" }, "<leader>dec", function()
  widgets.hover()
  widgets_mappings { "<leader>dec", "<A-x>" }
end, { desc = "debug evaluate on caret" })

map({ "n", "v" }, "<A-x>", function()
  widgets.hover()
  widgets_mappings { "<leader>dec", "<A-x>" }
end, { desc = "debug evaluate on caret" })

map({ "n", "v" }, "<leader>dei", function()
  widgets.hover(function()
    return vim.fn.input "  What's evaluatin'?: "
  end)
  widgets_mappings { "<leader>dei", "<A-X>" }
end, { desc = "debug evaluate input" })

map({ "n", "v" }, "<A-X>", function()
  widgets.hover(function()
    return vim.fn.input "  What's evaluatin'?: "
  end)
  widgets_mappings { "<leader>dei", "<A-X>" }
end, { desc = "debug evaluate input" })

map({ "n", "v" }, "<leader>db", function()
  dap.list_breakpoints()
  vim.cmd "Trouble qflist open focus=true"
end, { desc = "debug list breakpoints" })
