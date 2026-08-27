--- *debug_output* DAP session output, status, and tab-scoped session switching
---
--- Tracks nvim-dap sessions per tab: live output buffers, process liveness,
--- a Telescope picker, and a lualine component.
---
--- Public types live on `debug_output.state`:
---   DebugOutputSessionMeta, DebugOutputDapSession, DebugOutputPickerOpts,
---   DebugOutputPickerEntry, DebugOutputPickerAction.

local listeners = require "debug_output.listeners"
local lualine = require "debug_output.lualine"
local launching = require "debug_output.debug_launching"
local output = require "debug_output.output"
local picker = require "debug_output.picker"
local session = require "debug_output.session"
local state = require "debug_output.state"

local M = {}

--- Install DAP listeners and start process / session-sync timers.
function M.setup()
  listeners.setup()
  launching.setup()
end

--- Select and start a DAP launch configuration.
function M.launch()
  launching.launch()
end

--- Reconcile stored metadata with `dap.sessions()`.
function M.sync_sessions()
  session.sync()
end

--- Open the log for this tab's session, or pick one when several exist.
function M.show_output()
  local current = M.ensure_tab_session()
  if M.get_total_sessions_count() > 1 then
    picker.show(function(session_id)
      output.show_session(session_id)
    end)
    return
  end

  if current then
    local buf = output.find_buffer_for_session(current.id)
    if buf then
      local win = output.find_window_for_buffer(buf)
      if win then
        vim.api.nvim_set_current_win(win)
        return
      end
    end
    output.show_session(current.id)
    return
  end

  output.close_open_windows()
  picker.show(function(session_id)
    output.show_session(session_id)
  end)
end

--- Drop stored sessions/outputs and stop the fallback timers.
function M.clear()
  state.reset()
  listeners.stop_timers()
end

---@param action DebugOutputPickerAction
---@param opts? DebugOutputPickerOpts
function M.show_session_picker(action, opts)
  picker.show(action, opts)
end

---@return integer
function M.get_active_sessions_count()
  return session.active_count()
end

---@return integer
function M.get_total_sessions_count()
  return session.total_count()
end

---@param tab? integer
---@return DebugOutputDapSession|nil
function M.session_for_tab(tab)
  return session.for_tab(tab)
end

--- Focus a DAP session that belongs to the current tab.
---@return DebugOutputDapSession|nil
function M.ensure_tab_session()
  return session.ensure_tab()
end

---@return boolean
function M.should_show_session_picker()
  return M.get_active_sessions_count() > 1
end

---@param session_id? integer
---@return DebugOutputSessionMeta|table<integer, DebugOutputSessionMeta>|nil
function M.get_metadata(session_id)
  if session_id then
    return state.session_metadata[session_id]
  end
  return state.session_metadata
end

---@param session_id integer
---@return string[]|nil
function M.get_output(session_id)
  return state.session_outputs[session_id]
end

---@return DebugOutputLualineComponent
function M.lualine_component()
  return lualine.component()
end

return M
