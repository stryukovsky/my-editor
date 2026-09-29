-- Shared mutable session/output state for debug_output.
--
-- Everything that other modules read or write lives here so caches and
-- session tables stay in one place. Status caches (PID / tab / lualine)
-- are TTL'd and wiped together by invalidate_status_cache().

---@class DebugOutputSessionMeta
--- Launch-config name shown in the picker and lualine.
---@field name string
--- `config.program` or `config.request` ("launch" / "attach").
---@field command string
--- Adapter type (`pwa-node`, `go`, `codelldb`, …).
---@field type string
--- Local timestamp when `event_initialized` fired.
---@field started_at string
--- Set when the session ends or the OS process disappears.
---@field ended_at? string
--- False once terminated, exited, disconnected, or the PID died.
---@field active boolean
--- Neovim tabpage this session was started in.
---@field tab integer

---@class DebugOutputPidCacheEntry
---@field alive boolean result of `uv.kill(pid, 0)`
---@field at integer `vim.uv.hrtime()` when we last probed

---@class DebugOutputTabSessionCache
---@field tab integer|nil tabpage the cached session belongs to
---@field session DebugOutputDapSession|nil
---@field at integer `vim.uv.hrtime()`

---@class DebugOutputLiveRootsCache
---@field tab integer|nil
--- session.id → root (or fallback) DAP session still live in that tab.
---@field roots table<integer, DebugOutputDapSession>
---@field at integer `vim.uv.hrtime()`

---@class DebugOutputLualineCache
---@field text string last rendered component text (`""` = hidden)
---@field at integer `vim.uv.hrtime()`

--- Subset of an nvim-dap session we actually touch.
---@class DebugOutputDapSession
---@field id integer
---@field parent DebugOutputDapSession?
---@field children table<any, DebugOutputDapSession>
---@field closed boolean?
---@field stopped_thread_id integer|nil
---@field config table
---@field current_frame table?

local M = {}

--- session.id → stdout/stderr lines (ANSI already stripped).
---@type table<integer, string[]>
M.session_outputs = {}

--- session.id → metadata captured on `event_initialized`.
---@type table<integer, DebugOutputSessionMeta>
M.session_metadata = {}

--- session.id → set of scratch buffers currently showing that log.
---@type table<integer, table<integer, boolean>>
M.active_output_buffers = {}

--- session.id → OS pid from DAP `event_process.systemProcessId`.
---@type table<integer, integer>
M.session_pids = {}

---@type uv.uv_timer_t|nil
M.process_check_timer = nil
---@type uv.uv_timer_t|nil
M.session_sync_timer = nil

--- True after we wrap `dap.toggle_breakpoint` / `clear_breakpoints`.
M.breakpoint_hooks = false

---@type table<integer, DebugOutputPidCacheEntry>
M.pid_alive_cache = {}

---@type DebugOutputTabSessionCache
M.session_for_tab_cache = { tab = nil, session = nil, at = 0 }

---@type DebugOutputLiveRootsCache
M.live_roots_cache = { tab = nil, roots = {}, at = 0 }

---@type DebugOutputLualineCache
M.lualine_cache = { text = "", at = 0 }

M.PID_TTL_NS = 1e9 -- 1s
M.TAB_SESSION_TTL_NS = 2e8 -- 200ms
M.LUALINE_TTL_NS = 2e8 -- 200ms

M.PAUSE_ICON = "󰏤"
M.RUNNING_ICON = "●"
M.IDLE_ICON = "○"

--- Drop every TTL cache so the next read recomputes from live DAP state.
function M.invalidate_status_cache()
  M.pid_alive_cache = {}
  M.session_for_tab_cache = { tab = nil, session = nil, at = 0 }
  M.live_roots_cache = { tab = nil, roots = {}, at = 0 }
  M.lualine_cache = { text = "", at = 0 }
end

---@return integer tabpage
function M.current_tab()
  return vim.api.nvim_get_current_tabpage()
end

--- Wipe stored sessions/outputs. Does not stop the uv timers.
function M.reset()
  M.session_outputs = {}
  M.session_metadata = {}
  M.active_output_buffers = {}
  M.session_pids = {}
  M.invalidate_status_cache()
end

return M
