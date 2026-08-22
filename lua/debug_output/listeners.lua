-- Wire nvim-dap events and fallback timers into session/output state.

local notify = require "configs.notify"
local output = require "debug_output.output"
local process = require "debug_output.process"
local session = require "debug_output.session"
local state = require "debug_output.state"

local M = {}

local function notify_breakpoints_changed()
  vim.api.nvim_exec_autocmds("User", { pattern = "DapBreakpointsChanged" })
end

--- Wrap toggle/clear so Trouble / others can refresh on `User DapBreakpointsChanged`.
---@param dap table
local function hook_breakpoint_changes(dap)
  if state.breakpoint_hooks then
    return
  end
  state.breakpoint_hooks = true
  local orig_toggle = dap.toggle_breakpoint
  dap.toggle_breakpoint = function(...)
    orig_toggle(...)
    notify_breakpoints_changed()
  end
  local orig_clear = dap.clear_breakpoints
  dap.clear_breakpoints = function(...)
    orig_clear(...)
    notify_breakpoints_changed()
  end
end

---@param slot "process_check_timer"|"session_sync_timer"
---@param interval_ms integer
---@param fn fun()
---@param label string
local function start_timer(slot, interval_ms, fn, label)
  if state[slot] then
    return
  end
  local timer = vim.uv.new_timer()
  if timer == nil then
    notify.send("Debug Output", "Failed to create " .. label, vim.log.levels.WARN)
    return
  end
  state[slot] = timer
  timer:start(interval_ms, interval_ms, vim.schedule_wrap(fn))
end

---@param dap_session DebugOutputDapSession
local function on_session_ended(dap_session)
  session.mark_ended(dap_session)
  output.unlock_buffers(dap_session.id)
end

--- Install DAP listeners and start the 2s PID / 5s session-sync timers.
function M.setup()
  local dap = require "dap"
  hook_breakpoint_changes(dap)

  dap.defaults.fallback.on_output = output.capture
  dap.listeners.after.event_initialized["store_metadata"] = session.store_metadata
  dap.listeners.after.event_process["store_pid"] = session.store_pid
  dap.listeners.after.event_stopped["debug_output_status"] = state.invalidate_status_cache
  dap.listeners.after.event_continued["debug_output_status"] = state.invalidate_status_cache
  dap.listeners.before.event_terminated["mark_ended"] = on_session_ended
  dap.listeners.before.event_exited["mark_ended"] = on_session_ended
  dap.listeners.before.disconnect["mark_ended"] = on_session_ended

  start_timer("process_check_timer", 2000, process.check_all, "process check timer")
  start_timer("session_sync_timer", 5000, session.sync, "session sync timer")
end

function M.stop_timers()
  if state.process_check_timer then
    state.process_check_timer:stop()
    state.process_check_timer = nil
  end
  if state.session_sync_timer then
    state.session_sync_timer:stop()
    state.session_sync_timer = nil
  end
end

return M
