-- DAP Output Manager Module
-- Manages debug session outputs with live updates and session tracking

local M = {}
local notify = require "configs.notify"

-- Private state
local session_outputs = {}
local session_metadata = {}
local active_output_buffers = {}
local session_pids = {} -- Track PIDs for each session
local process_check_timer = nil -- Timer for periodic process checking
local session_sync_timer = nil -- Timer for session synchronization
local breakpoint_hooks = false
local pid_alive_cache = {} ---@type table<integer, { alive: boolean, at: integer }>
local session_for_tab_cache = { tab = nil, session = nil, at = 0 }
local live_roots_cache = { tab = nil, roots = {}, at = 0 }
local lualine_cache = { text = "", at = 0 }
local PID_TTL_NS = 1e9 -- 1s
local TAB_SESSION_TTL_NS = 2e8 -- 200ms
local LUALINE_TTL_NS = 2e8 -- 200ms

local PAUSE_ICON = "󰏤"
local RUNNING_ICON = "●"
local IDLE_ICON = "○"

-- Initialize random seed once
math.randomseed(os.time())

local function random_3char()
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  local result = {}

  for _ = 1, 3 do
    local index = math.random(#chars)
    -- Берем один символ в позиции index
    result[#result + 1] = chars:sub(index, index)
  end

  return table.concat(result)
end

local function strip_ansi(str)
  -- CSI: ESC [ <params: digits ; ? > = <  > <final byte>
  str = str:gsub("\27%[[%d;?]*[%a@~]", "")
  -- OSC/DCS/SOS/PM/APC terminated by ST (ESC \)
  str = str:gsub("\27[%]PX^_].-\27\\", "")
  -- OSC/DCS/SOS/PM/APC terminated by BEL
  str = str:gsub("\27[%]PX^_].-\7", "")
  -- Simple two-byte escapes: ESC <letter>
  str = str:gsub("\27[%a\\^_]", "")
  return str
end

local function invalidate_status_cache()
  pid_alive_cache = {}
  session_for_tab_cache = { tab = nil, session = nil, at = 0 }
  live_roots_cache = { tab = nil, roots = {}, at = 0 }
  lualine_cache = { text = "", at = 0 }
end

--- Cheap existence check: `kill(pid, 0)` via libuv, never a shell.
local function check_process_running(pid)
  if not pid then
    return false
  end
  local now = vim.uv.hrtime()
  local cached = pid_alive_cache[pid]
  if cached and (now - cached.at) < PID_TTL_NS then
    return cached.alive
  end
  local alive = vim.uv.kill(pid, 0) == 0
  pid_alive_cache[pid] = { alive = alive, at = now }
  return alive
end

local function check_all_processes()
  local changed = false
  for session_id, pid in pairs(session_pids) do
    -- If we have metadata for this session and it's marked as active
    if session_metadata[session_id] and session_metadata[session_id].active then
      -- Check if the process is actually still running
      if not check_process_running(pid) then
        -- Process is not running, mark session as inactive
        session_metadata[session_id].active = false
        session_metadata[session_id].ended_at = os.date "%Y-%m-%d %H:%M:%S"
        changed = true
        -- Don't remove from session_pids yet as we might want to keep this for reference
      end
    end
  end
  if changed then
    invalidate_status_cache()
  end
end

local function current_tab()
  return vim.api.nvim_get_current_tabpage()
end

local function each_dap_session(fn)
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

local function find_dap_session(session_id)
  local found
  each_dap_session(function(session)
    if session.id == session_id then
      found = session
    end
  end)
  return found
end

local function session_root(session)
  while session and session.parent do
    session = session.parent
  end
  return session
end

local function session_tab(session)
  local current = session
  while current do
    local meta = session_metadata[current.id]
    if meta and meta.tab then
      return meta.tab
    end
    current = current.parent
  end
end

--- True when this session is still a real debuggee, not a leftover adapter.
--- Does not probe the OS; crashed processes are marked inactive by the timer.
local function session_is_live(session)
  if not session or session.closed then
    return false
  end
  local meta = session_metadata[session.id]
  if meta and not meta.active then
    return false
  end
  if session.stopped_thread_id then
    return true
  end
  local has_children = false
  for _, child in pairs(session.children or {}) do
    has_children = true
    if session_is_live(child) then
      return true
    end
  end
  -- Parent whose children already died is a leftover adapter.
  if has_children then
    return false
  end
  return meta == nil or meta.active ~= false
end

local function live_roots_for_tab(tab)
  tab = tab or current_tab()
  local now = vim.uv.hrtime()
  if live_roots_cache.tab == tab and (now - live_roots_cache.at) < TAB_SESSION_TTL_NS then
    return live_roots_cache.roots
  end
  local roots = {}
  each_dap_session(function(session)
    if not session_is_live(session) then
      return
    end
    local sid_tab = session_tab(session)
    if sid_tab ~= nil and sid_tab ~= tab then
      return
    end
    local root = session_root(session)
    if session_is_live(root) then
      roots[root.id] = root
    elseif session_is_live(session) then
      roots[session.id] = session
    end
  end)
  live_roots_cache = { tab = tab, roots = roots, at = now }
  return roots
end

local function meta_for_session(session)
  if not session then
    return nil
  end
  local meta = session_metadata[session.id]
  if meta then
    return meta
  end
  for _, child in pairs(session.children or {}) do
    local child_meta = session_metadata[child.id]
    if child_meta then
      return child_meta
    end
  end
end

local function session_status_icon(session_id, session, meta)
  session = session or find_dap_session(session_id)
  if session and session.stopped_thread_id then
    return PAUSE_ICON
  end
  if session and session_is_live(session) then
    return RUNNING_ICON
  end
  if meta and meta.active then
    return RUNNING_ICON
  end
  return IDLE_ICON
end

local function metadata_for_tab(tab)
  tab = tab or current_tab()
  local result = {}
  for session_id, meta in pairs(session_metadata) do
    if meta.tab == tab then
      result[session_id] = meta
    end
  end
  return result
end

local function notify_breakpoints_changed()
  vim.api.nvim_exec_autocmds("User", { pattern = "DapBreakpointsChanged" })
end

local function hook_breakpoint_changes(dap)
  if breakpoint_hooks then
    return
  end
  breakpoint_hooks = true
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

local function find_window_for_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local win_buf = vim.api.nvim_win_get_buf(win)
      if win_buf == buf then
        return win
      end
    end
  end
  return nil
end

local function find_buffer_for_session(session_id)
  if not active_output_buffers[session_id] then
    return nil
  end

  for buf, _ in pairs(active_output_buffers[session_id]) do
    if vim.api.nvim_buf_is_valid(buf) then
      return buf
    else
      -- Clean up invalid buffer reference
      active_output_buffers[session_id][buf] = nil
    end
  end
  return nil
end

local function show_session_output(session_id)
  local outputs = session_outputs[session_id]
  if not outputs or #outputs == 0 then
    notify.send("Debug Output", "No output for this session")
    return
  end

  -- Check if buffer already exists and is visible
  local existing_buf = find_buffer_for_session(session_id)
  if existing_buf then
    local win = find_window_for_buffer(existing_buf)
    if win and vim.api.nvim_win_is_valid(win) then
      -- Focus existing window instead of creating new one
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "log"

  -- Add session info header
  local header = {}
  local meta = session_metadata[session_id]
  if meta then
    table.insert(header, "=== DAP Session Output ===")
    table.insert(header, "Name: " .. meta.name)
    table.insert(header, "Command: " .. meta.command)
    table.insert(header, "Type: " .. meta.type)
    table.insert(header, "Started: " .. meta.started_at)
    if meta.ended_at then
      table.insert(header, "Ended: " .. meta.ended_at)
    end
    table.insert(header, "Status: " .. (meta.active and "Active" or "Ended"))
    table.insert(header, "")
    table.insert(header, "--- Output ---")
    table.insert(header, "")
  end

  -- Combine header and outputs
  local content = vim.list_extend(header, vim.tbl_map(strip_ansi, outputs))

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)

  -- Register this buffer for live updates
  if not active_output_buffers[session_id] then
    active_output_buffers[session_id] = {}
  end
  active_output_buffers[session_id][buf] = true

  -- Clean up when buffer is deleted
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = buf,
    callback = function()
      if active_output_buffers[session_id] then
        active_output_buffers[session_id][buf] = nil
      end
    end,
  })

  -- Open in split window
  vim.cmd "split"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  if not pcall(function()
    vim.api.nvim_buf_set_name(buf, "DAP Output: " .. (meta and meta.name or session_id))
  end) then
    vim.api.nvim_buf_set_name(buf, "DAP Output: " .. (meta and meta.name or session_id) .. " " .. random_3char())
  end
  -- Add 'q' mapping to close the window
  vim.keymap.set("n", "q", function()
    vim.cmd "close"
  end, { buffer = buf, nowait = true, silent = true, desc = "Close DAP output window" })

  -- Make buffer read-only
  vim.bo[buf].modifiable = false

  -- Scroll to bottom
  vim.schedule(function()
    local last_line = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(win, { last_line, 0 })
  end)
end

--- Show telescope picker for session selection and execute action
--- @param action function Callback function(session_id, meta, dap_session) to execute after selection
--- @param opts? { live_only?: boolean, notify_switch?: boolean }
local function show_session_picker(action, opts)
  opts = opts or {}
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not has_telescope then
    notify.send("Debug Output", "Telescope not available", vim.log.levels.WARN)
    return
  end

  local dap = require "dap"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  local sessions = {}
  if opts.live_only then
    for _, root in pairs(live_roots_for_tab()) do
      local meta = meta_for_session(root)
        or {
          name = root.config and root.config.name or "DAP",
          command = root.config and (root.config.program or root.config.request) or "",
          started_at = "",
          active = true,
        }
      table.insert(sessions, {
        session_id = root.id,
        display = string.format("[%s] %s - %s (%s)", session_status_icon(root.id, root, meta), meta.name, meta.command, meta.started_at),
        meta = meta,
      })
    end
  else
    for session_id, meta in pairs(metadata_for_tab()) do
      table.insert(sessions, {
        session_id = session_id,
        display = string.format("[%s] %s - %s (%s)", session_status_icon(session_id, nil, meta), meta.name, meta.command, meta.started_at),
        meta = meta,
      })
    end
  end

  if #sessions == 0 then
    notify.send("Debug Output", "No DAP sessions found")
    return
  end

  -- Sort: active first, then by start time, with actual process status checking
  table.sort(sessions, function(a, b)
    -- First check actual process status if we have PID
    local a_pid = session_pids[a.session_id]
    local b_pid = session_pids[b.session_id]

    if a_pid and b_pid then
      -- Check actual process status
      local a_running = check_process_running(a_pid)
      local b_running = check_process_running(b_pid)

      if a_running ~= b_running then
        return a_running
      end
    end

    -- Fall back to metadata active status
    if a.meta.active ~= b.meta.active then
      return a.meta.active
    end

    return a.meta.started_at > b.meta.started_at
  end)

  pickers
    .new({}, {
      initial_mode = "normal",
      prompt_title = "DAP Sessions",
      finder = finders.new_table {
        results = sessions,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.display,
            ordinal = entry.display,
          }
        end,
      },
      sorter = conf.generic_sorter {},

      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt_bufnr, _)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)

          local session_id = selection.value.session_id
          local meta = selection.value.meta
          local dap_session = find_dap_session(session_id)
          if dap_session and session_is_live(dap_session) then
            dap.set_session(dap_session)
            if opts.notify_switch ~= false then
              notify.send("Debug Output", "Switched to session: " .. meta.name)
            end
          else
            dap_session = nil
          end

          -- Execute the provided action
          if action then
            action(session_id, meta, dap_session)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Public API

--- Setup DAP output capture and listeners
function M.setup()
  local dap = require "dap"
  hook_breakpoint_changes(dap)

  -- Capture output
  dap.defaults.fallback.on_output = function(session, event)
    local session_id = session.id
    if not session_outputs[session_id] then
      session_outputs[session_id] = {}
    end

    -- Split output by newlines and append each line
    local lines = vim.split(event.output, "\n", { plain = true })
    for _, line in ipairs(lines) do
      table.insert(session_outputs[session_id], strip_ansi(line))
    end

    -- Update all buffers showing this session's output
    if active_output_buffers[session_id] then
      for buf, _ in pairs(active_output_buffers[session_id]) do
        if vim.api.nvim_buf_is_valid(buf) then
          vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(buf) then
              return
            end
            vim.bo[buf].modifiable = true
            local current_lines = vim.api.nvim_buf_line_count(buf)

            -- Follow output only when the cursor is already on the last line.
            local wins_to_follow = {}
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                if vim.api.nvim_win_get_cursor(win)[1] >= current_lines then
                  wins_to_follow[#wins_to_follow + 1] = win
                end
              end
            end

            local clean_lines = vim.tbl_map(strip_ansi, lines)
            vim.api.nvim_buf_set_lines(buf, current_lines, -1, false, clean_lines)
            vim.bo[buf].modifiable = false

            local last_line = vim.api.nvim_buf_line_count(buf)
            for _, win in ipairs(wins_to_follow) do
              if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_set_cursor(win, { last_line, 0 })
              end
            end
          end)
        else
          active_output_buffers[session_id][buf] = nil
        end
      end
    end
  end

  -- Capture session metadata when session starts
  dap.listeners.after.event_initialized["store_metadata"] = function(session)
    local session_id = session.id
    session_metadata[session_id] = {
      command = session.config.program or session.config.request or "Unknown",
      name = session.config.name or "Unnamed",
      type = session.config.type or "Unknown",
      started_at = os.date "%Y-%m-%d %H:%M:%S",
      active = true,
      tab = current_tab(),
    }
    invalidate_status_cache()
  end

  -- Capture process ID when process event is received
  dap.listeners.after.event_process["store_pid"] = function(session, body)
    if body.systemProcessId then
      session_pids[session.id] = body.systemProcessId
      invalidate_status_cache()
    end
  end

  dap.listeners.after.event_stopped["debug_output_status"] = invalidate_status_cache
  dap.listeners.after.event_continued["debug_output_status"] = invalidate_status_cache

  -- Subscribe to additional DAP termination events for optimized behavior
  -- Especially useful for DAPs which emit these specific events
  -- Timers remain as a fallback mechanism for robustness

  -- Session termination handler
  local function session_terminated(session)
    if session_metadata[session.id] then
      session_metadata[session.id].active = false
      session_metadata[session.id].ended_at = os.date "%Y-%m-%d %H:%M:%S"

      -- Clean up PID tracking
      session_pids[session.id] = nil

      -- Make all buffers for this session modifiable again
      if active_output_buffers[session.id] then
        for buf, _ in pairs(active_output_buffers[session.id]) do
          if vim.api.nvim_buf_is_valid(buf) then
            vim.schedule(function()
              vim.bo[buf].modifiable = true
            end)
          end
        end
      end
    end

    -- A parent adapter is not its own debuggee once every child has ended.
    local parent = session.parent
    if parent and session_metadata[parent.id] then
      local any_live_child = false
      for _, child in pairs(parent.children or {}) do
        if child ~= session and session_is_live(child) then
          any_live_child = true
          break
        end
      end
      if not any_live_child then
        session_metadata[parent.id].active = false
        session_metadata[parent.id].ended_at = session_metadata[parent.id].ended_at or os.date "%Y-%m-%d %H:%M:%S"
      end
    end
    invalidate_status_cache()
  end

  -- Mark session as ended
  dap.listeners.before.event_terminated["mark_ended"] = session_terminated
  dap.listeners.before.event_exited["mark_ended"] = session_terminated
  -- Additional termination events for robustness
  dap.listeners.before.disconnect["mark_ended"] = session_terminated

  -- Start periodic process checking every 2 seconds
  if not process_check_timer then
    process_check_timer = vim.uv.new_timer()
    if process_check_timer == nil then
      notify.send("Debug Output", "Failed to create process check timer", vim.log.levels.WARN)
    else
      process_check_timer:start(2000, 2000, vim.schedule_wrap(check_all_processes))
    end
  end

  -- Start periodic session synchronization every 5 seconds
  if not session_sync_timer then
    session_sync_timer = vim.uv.new_timer()
    if session_sync_timer == nil then
      notify.send("Debug Output", "Failed to create session sync timer", vim.log.levels.WARN)
    else
      session_sync_timer:start(5000, 5000, vim.schedule_wrap(M.sync_sessions))
    end
  end
end

function M.sync_sessions()
  local dap = require "dap"
  local actual_sessions = dap.sessions()

  -- Create a set of actual session IDs for quick lookup
  local actual_session_ids = {}
  for _, session in pairs(actual_sessions) do
    actual_session_ids[session.id] = true
  end

  local changed = false
  -- Mark sessions as inactive if they no longer exist in DAP
  for session_id, meta in pairs(session_metadata) do
    if meta.active and not actual_session_ids[session_id] then
      meta.active = false
      meta.ended_at = os.date "%Y-%m-%d %H:%M:%S"
      session_pids[session_id] = nil
      changed = true
    end
  end
  if changed then
    invalidate_status_cache()
  end
end

--- Show DAP output for current or selected session
function M.show_output()
  local session = M.ensure_tab_session()

  local total_sessions = M.get_total_sessions_count()

  -- If more than 1 session ever existed in this tab, always show picker
  if total_sessions > 1 then
    show_session_picker(function(session_id, meta, dap_session)
      show_session_output(session_id)
    end)
    return
  end

  -- Single or no active session - proceed with original logic
  if session then
    local session_id = session.id
    local buf = find_buffer_for_session(session_id)

    -- If buffer exists, find its window and focus it
    if buf then
      local win = find_window_for_buffer(buf)
      if win then
        vim.api.nvim_set_current_win(win)
        return
      end
    end

    -- No existing buffer/window, create new one
    show_session_output(session_id)
    return
  end

  -- No active session - close any open output windows
  for session_id, buffers in pairs(active_output_buffers) do
    for buf, _ in pairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        local win = find_window_for_buffer(buf)
        if win then
          vim.api.nvim_win_close(win, false)
        end
      end
    end
  end

  -- Show telescope picker
  show_session_picker(function(session_id, meta, dap_session)
    show_session_output(session_id)
  end)
end

--- Clear all stored session data
function M.clear()
  session_outputs = {}
  session_metadata = {}
  active_output_buffers = {}
  session_pids = {}
  invalidate_status_cache()

  -- Stop timers if they exist
  if process_check_timer then
    process_check_timer:stop()
    process_check_timer = nil
  end

  if session_sync_timer then
    session_sync_timer:stop()
    session_sync_timer = nil
  end
end

--- Show telescope picker for session selection
--- @param action function Callback function(session_id, meta, dap_session) to execute after selection
--- @param opts? { live_only?: boolean, notify_switch?: boolean }
function M.show_session_picker(action, opts)
  show_session_picker(action, opts)
end

function M.get_active_sessions_count()
  return vim.tbl_count(live_roots_for_tab())
end

function M.get_total_sessions_count()
  return vim.tbl_count(metadata_for_tab())
end

--- DAP session bound to the current tab, if any.
function M.session_for_tab(tab)
  tab = tab or current_tab()
  local now = vim.uv.hrtime()
  if session_for_tab_cache.tab == tab and (now - session_for_tab_cache.at) < TAB_SESSION_TTL_NS then
    return session_for_tab_cache.session
  end
  local dap = require "dap"
  local current = dap.session()
  local found
  if current and session_is_live(current) then
    local sid_tab = session_tab(current)
    if sid_tab == nil then
      local meta = session_metadata[current.id]
      if meta then
        meta.tab = tab
      end
      found = current
    elseif sid_tab == tab then
      found = current
    end
  end
  if not found then
    local fallback
    for _, root in pairs(live_roots_for_tab(tab)) do
      if root.stopped_thread_id then
        fallback = root
        break
      end
      local stopped_child
      for _, child in pairs(root.children or {}) do
        if session_is_live(child) and child.stopped_thread_id then
          stopped_child = child
          break
        end
      end
      if stopped_child then
        fallback = stopped_child
        break
      end
      fallback = fallback or root
    end
    found = fallback
  end
  session_for_tab_cache = { tab = tab, session = found, at = now }
  return found
end

--- Focus a DAP session that belongs to the current tab.
--- @return table|nil
function M.ensure_tab_session()
  local session = M.session_for_tab()
  if session then
    require("dap").set_session(session)
  end
  return session
end

--- Show a picker only when this tab has more than one live debuggee.
function M.should_show_session_picker()
  return M.get_active_sessions_count() > 1
end

--- Get session metadata
--- @param session_id string|nil Session ID (nil for all sessions)
--- @return table Session metadata
function M.get_metadata(session_id)
  if session_id then
    return session_metadata[session_id]
  end
  return session_metadata
end

--- Get session output
--- @param session_id string Session ID
--- @return table|nil Session output lines
function M.get_output(session_id)
  return session_outputs[session_id]
end

--- Get lualine component for current DAP session
--- @return table Lualine component configuration
function M.lualine_component()
  local function text()
    local now = vim.uv.hrtime()
    if (now - lualine_cache.at) < LUALINE_TTL_NS then
      return lualine_cache.text
    end

    local session = M.session_for_tab()
    local result = ""
    if session then
      local meta = session_metadata[session.id]
      if not meta then
        result = "DAP"
      else
        local status_icon = session_status_icon(session.id, session, meta)
        local name = meta.name or "DAP"
        local active_count = M.get_active_sessions_count()
        if active_count > 1 then
          result = string.format("%s %s (%d)", status_icon, name, active_count)
        else
          result = string.format("%s %s", status_icon, name)
        end
      end
    end
    lualine_cache = { text = result, at = now }
    return result
  end
  return {
    text,
    cond = function()
      return text() ~= ""
    end,
  }
end

return M
