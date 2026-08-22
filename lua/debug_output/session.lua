-- Walk the nvim-dap session tree and decide which debuggee belongs to a tab.
--
-- A "root" is the top-most live session (parent adapters with dead children
-- are ignored). Sessions are scoped by the tabpage stored on SessionMeta.

local state = require "debug_output.state"

local M = {}

---@alias DebugOutputSessionVisitor fun(session: DebugOutputDapSession)

--- Depth-first walk of every DAP session, including children.
---@param fn DebugOutputSessionVisitor
function M.each_dap_session(fn)
  local dap = require "dap"
  local seen = {}
  local function walk(session)
    if not session or seen[session] then
      return
    end
    seen[session] = true
    fn(session)
    for _, child in pairs(session.children or {}) do
      walk(child)
    end
  end
  for _, session in pairs(dap.sessions()) do
    walk(session)
  end
end

---@param session_id integer
---@return DebugOutputDapSession|nil
function M.find_dap_session(session_id)
  local found
  M.each_dap_session(function(session)
    if session.id == session_id then
      found = session
    end
  end)
  return found
end

--- Walk `parent` until the top-most adapter/session.
---@param session DebugOutputDapSession|nil
---@return DebugOutputDapSession|nil
function M.root(session)
  while session and session.parent do
    session = session.parent
  end
  return session
end

--- Tabpage recorded on this session or an ancestor.
---@param session DebugOutputDapSession|nil
---@return integer|nil
function M.tab(session)
  local current = session
  while current do
    local meta = state.session_metadata[current.id]
    if meta and meta.tab then
      return meta.tab
    end
    current = current.parent
  end
end

--- True when this session is still a real debuggee, not a leftover adapter.
--- Does not probe the OS; crashed processes are marked inactive by the timer.
---@param session DebugOutputDapSession|nil
---@return boolean
function M.is_live(session)
  if not session or session.closed then
    return false
  end
  local meta = state.session_metadata[session.id]
  if meta and not meta.active then
    return false
  end
  if session.stopped_thread_id then
    return true
  end
  local has_children = false
  for _, child in pairs(session.children or {}) do
    has_children = true
    if M.is_live(child) then
      return true
    end
  end
  -- Parent whose children already died is a leftover adapter.
  if has_children then
    return false
  end
  return meta == nil or meta.active ~= false
end

--- Live root sessions that belong to `tab` (or the current tab).
---@param tab? integer
---@return table<integer, DebugOutputDapSession>
function M.live_roots_for_tab(tab)
  tab = tab or state.current_tab()
  local now = vim.uv.hrtime()
  if state.live_roots_cache.tab == tab and (now - state.live_roots_cache.at) < state.TAB_SESSION_TTL_NS then
    return state.live_roots_cache.roots
  end
  local roots = {}
  M.each_dap_session(function(session)
    if not M.is_live(session) then
      return
    end
    local sid_tab = M.tab(session)
    if sid_tab ~= nil and sid_tab ~= tab then
      return
    end
    local root = M.root(session)
    if M.is_live(root) then
      roots[root.id] = root
    elseif M.is_live(session) then
      roots[session.id] = session
    end
  end)
  state.live_roots_cache = { tab = tab, roots = roots, at = now }
  return roots
end

--- Metadata for this session, or the first child that has some.
---@param session DebugOutputDapSession|nil
---@return DebugOutputSessionMeta|nil
function M.meta_for(session)
  if not session then
    return nil
  end
  local meta = state.session_metadata[session.id]
  if meta then
    return meta
  end
  for _, child in pairs(session.children or {}) do
    local child_meta = state.session_metadata[child.id]
    if child_meta then
      return child_meta
    end
  end
end

--- Pause / running / idle glyph for picker and lualine.
---@param session_id integer
---@param session DebugOutputDapSession|nil
---@param meta DebugOutputSessionMeta|nil
---@return string
function M.status_icon(session_id, session, meta)
  session = session or M.find_dap_session(session_id)
  if session and session.stopped_thread_id then
    return state.PAUSE_ICON
  end
  if session and M.is_live(session) then
    return state.RUNNING_ICON
  end
  if meta and meta.active then
    return state.RUNNING_ICON
  end
  return state.IDLE_ICON
end

---@param tab? integer
---@return table<integer, DebugOutputSessionMeta>
function M.metadata_for_tab(tab)
  tab = tab or state.current_tab()
  local result = {}
  for session_id, meta in pairs(state.session_metadata) do
    if meta.tab == tab then
      result[session_id] = meta
    end
  end
  return result
end

---@param tab? integer
---@return integer
function M.active_count(tab)
  return vim.tbl_count(M.live_roots_for_tab(tab))
end

---@param tab? integer
---@return integer
function M.total_count(tab)
  return vim.tbl_count(M.metadata_for_tab(tab))
end

--- Prefer a stopped thread in this tab; otherwise any live root.
---@param tab integer
---@return DebugOutputDapSession|nil
local function first_live_fallback(tab)
  local fallback
  for _, root in pairs(M.live_roots_for_tab(tab)) do
    if root.stopped_thread_id then
      return root
    end
    for _, child in pairs(root.children or {}) do
      if M.is_live(child) and child.stopped_thread_id then
        return child
      end
    end
    fallback = fallback or root
  end
  return fallback
end

--- DAP session bound to `tab`, if any. Claims an unbound live session.
---@param tab? integer
---@return DebugOutputDapSession|nil
function M.for_tab(tab)
  tab = tab or state.current_tab()
  local now = vim.uv.hrtime()
  if state.session_for_tab_cache.tab == tab and (now - state.session_for_tab_cache.at) < state.TAB_SESSION_TTL_NS then
    return state.session_for_tab_cache.session
  end
  local dap = require "dap"
  local current = dap.session()
  local found
  if current and M.is_live(current) then
    local sid_tab = M.tab(current)
    if sid_tab == nil then
      local meta = state.session_metadata[current.id]
      if meta then
        meta.tab = tab
      end
      found = current
    elseif sid_tab == tab then
      found = current
    end
  end
  found = found or first_live_fallback(tab)
  state.session_for_tab_cache = { tab = tab, session = found, at = now }
  return found
end

--- Focus a DAP session that belongs to the current tab.
---@return DebugOutputDapSession|nil
function M.ensure_tab()
  local session = M.for_tab()
  if session then
    require("dap").set_session(session)
  end
  return session
end

--- DAP `event_initialized` handler: record name/command/tab.
---@param session DebugOutputDapSession
function M.store_metadata(session)
  state.session_metadata[session.id] = {
    command = session.config.program or session.config.request or "Unknown",
    name = session.config.name or "Unnamed",
    type = session.config.type or "Unknown",
    started_at = os.date "%Y-%m-%d %H:%M:%S",
    active = true,
    tab = state.current_tab(),
  }
  state.invalidate_status_cache()
end

--- DAP `event_process` handler.
---@param session DebugOutputDapSession
---@param body { systemProcessId?: integer }
function M.store_pid(session, body)
  if body.systemProcessId then
    state.session_pids[session.id] = body.systemProcessId
    state.invalidate_status_cache()
  end
end

--- Mark this session (and a childless parent adapter) inactive.
---@param session DebugOutputDapSession
function M.mark_ended(session)
  local meta = state.session_metadata[session.id]
  if meta then
    meta.active = false
    meta.ended_at = os.date "%Y-%m-%d %H:%M:%S"
    state.session_pids[session.id] = nil
  end

  -- A parent adapter is not its own debuggee once every child has ended.
  local parent = session.parent
  if parent and state.session_metadata[parent.id] then
    local any_live_child = false
    for _, child in pairs(parent.children or {}) do
      if child ~= session and M.is_live(child) then
        any_live_child = true
        break
      end
    end
    if not any_live_child then
      local parent_meta = state.session_metadata[parent.id]
      parent_meta.active = false
      parent_meta.ended_at = parent_meta.ended_at or os.date "%Y-%m-%d %H:%M:%S"
    end
  end
  state.invalidate_status_cache()
end

--- Fallback: mark metadata inactive when DAP no longer lists the session.
function M.sync()
  local actual_session_ids = {}
  for _, session in pairs(require("dap").sessions()) do
    actual_session_ids[session.id] = true
  end

  local changed = false
  for session_id, meta in pairs(state.session_metadata) do
    if meta.active and not actual_session_ids[session_id] then
      meta.active = false
      meta.ended_at = os.date "%Y-%m-%d %H:%M:%S"
      state.session_pids[session_id] = nil
      changed = true
    end
  end
  if changed then
    state.invalidate_status_cache()
  end
end

return M
