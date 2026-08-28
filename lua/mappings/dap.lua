---@diagnostic disable: duplicate-set-field
local map = require "mappings.map"
local widgets = require "dap.ui.widgets"
local dap = require "dap"
local debug_output = require "debug_output"
local notify = require "configs.notify"
-- local trouble = require "trouble"

-- debugger
map("n", "<leader>dd", function()
  debug_output.launch()
end, { desc = "debug select and start" })

map("n", "<A-n>", function()
  dap.continue()
end, { desc = "debug continue" })

map("n", "<leader>dp", function()
  if debug_output.get_active_sessions_count() > 1 then
    debug_output.show_session_picker(function(_, meta, dap_session)
      if dap_session then
        dap.pause()
        notify.replace("dap.pause", "Debug", "Paused " .. meta.name)
      end
    end, { live_only = true, notify_switch = false })
  elseif debug_output.ensure_tab_session() then
    dap.pause()
  else
    vim.notify("No debug session in this tab", vim.log.levels.WARN)
  end
end, { desc = "debug pause" })

map("n", "<leader>dk", function()
  if debug_output.get_active_sessions_count() > 1 then
    debug_output.show_session_picker(function(_, meta, dap_session)
      if dap_session then
        dap.terminate()
        notify.replace("dap.kill", "Debug", "Killed " .. meta.name)
      end
    end, { live_only = true, notify_switch = false })
  elseif debug_output.ensure_tab_session() then
    dap.terminate()
  else
    vim.notify("No debug session in this tab", vim.log.levels.WARN)
  end
end, { desc = "debug kill" })

map("n", "<leader>dc", function()
  if debug_output.get_active_sessions_count() > 1 then
    debug_output.show_session_picker(function(_, meta, dap_session)
      if dap_session then
        notify.replace("dap.choose", "Debug", "Chosen " .. meta.name)
      end
    end, { live_only = true })
  end
end, { desc = "debug choose session" })

map("n", "<leader>drf", function()
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

map("n", "<leader>B", function()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(cond)
    if not cond or cond == "" then
      return
    end
    dap.set_breakpoint(cond)
  end)
end, { desc = "debug conditional breakpoint" })

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
  debug_output.show_output()
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

map("n", "<leader>dw", function()
  local session = debug_output.ensure_tab_session()
  if not session then
    vim.notify("No debug session in this tab", vim.log.levels.WARN)
    return
  end
  if not session.stopped_thread_id and not session.current_frame then
    vim.notify("Debuggee is not stopped", vim.log.levels.INFO)
    return
  end
  dap.focus_frame()
end, { desc = "debug go to stopped position" })

map({ "n", "v" }, "<leader>db", function()
  require("utils.ui_prevent_mess")()
  require("trouble").open { mode = "dap_breakpoints", focus = true }
end, { desc = "debug list breakpoints" })
