local state = require "debug_output.state"

local M = {}

--- Cheap existence check: `kill(pid, 0)` via libuv, never a shell.
--- Result is cached for `state.PID_TTL_NS`.
---@param pid integer|nil
---@return boolean
function M.is_running(pid)
  if not pid then
    return false
  end
  local now = vim.uv.hrtime()
  local cached = state.pid_alive_cache[pid]
  if cached and (now - cached.at) < state.PID_TTL_NS then
    return cached.alive
  end
  local alive = vim.uv.kill(pid, 0) == 0
  state.pid_alive_cache[pid] = { alive = alive, at = now }
  return alive
end

--- Mark metadata inactive when a tracked PID has exited.
--- Called on a 2s timer from listeners.setup().
function M.check_all()
  local changed = false
  for session_id, pid in pairs(state.session_pids) do
    local meta = state.session_metadata[session_id]
    if meta and meta.active and not M.is_running(pid) then
      meta.active = false
      meta.ended_at = os.date "%Y-%m-%d %H:%M:%S"
      changed = true
    end
  end
  if changed then
    state.invalidate_status_cache()
  end
end

return M
