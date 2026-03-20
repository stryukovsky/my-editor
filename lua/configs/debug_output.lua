-- DAP Output Manager Module
-- Manages debug session outputs with live updates and session tracking

local M = {}

-- Private state
local session_outputs = {}
local session_metadata = {}
local active_output_buffers = {}
local session_pids = {} -- Track PIDs for each session
local process_check_timer = nil -- Timer for periodic process checking
local session_sync_timer = nil -- Timer for session synchronization

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

local function check_process_running(pid)
  if not pid then
    return false
  end

  -- Check if process is still running using system command
  local command = string.format("kill -0 %d 2>/dev/null && echo 'running' || echo 'stopped'", pid)
  local handle = io.popen(command)
  if handle then
    local result = handle:read "*a"
    handle:close()
    return result:match "running" ~= nil
  end
  return false
end

local function check_all_processes()
  for session_id, pid in pairs(session_pids) do
    -- If we have metadata for this session and it's marked as active
    if session_metadata[session_id] and session_metadata[session_id].active then
      -- Check if the process is actually still running
      if not check_process_running(pid) then
        -- Process is not running, mark session as inactive
        session_metadata[session_id].active = false
        session_metadata[session_id].ended_at = os.date "%Y-%m-%d %H:%M:%S"
        -- Don't remove from session_pids yet as we might want to keep this for reference
      end
    end
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
    vim.notify("No output for this session", vim.log.levels.INFO)
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
  local content = vim.list_extend(header, outputs)

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
local function show_session_picker(action)
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not has_telescope then
    vim.notify("Telescope not available", vim.log.levels.WARN)
    return
  end

  local dap = require "dap"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  -- Build list of sessions
  local sessions = {}
  for session_id, meta in pairs(session_metadata) do
    table.insert(sessions, {
      session_id = session_id,
      display = string.format("[%s] %s - %s (%s)", meta.active and "●" or "○", meta.name, meta.command, meta.started_at),
      meta = meta,
    })
  end

  if #sessions == 0 then
    vim.notify("No DAP sessions found", vim.log.levels.INFO)
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
          local dap_session = nil

          -- Set as current session if it's active
          if meta.active then
            -- Find the session object in dap sessions
            for _, sess in pairs(dap.sessions()) do
              if sess.id == session_id then
                dap.set_session(sess)
                dap_session = sess
                vim.notify("Switched to session: " .. meta.name, vim.log.levels.INFO)
                break
              end
            end
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

  -- Capture output
  dap.defaults.fallback.on_output = function(session, event)
    local session_id = session.id
    if not session_outputs[session_id] then
      session_outputs[session_id] = {}
    end

    -- Split output by newlines and append each line
    local lines = vim.split(event.output, "\n", { plain = true })
    for _, line in ipairs(lines) do
      table.insert(session_outputs[session_id], line)
    end

    -- Update all buffers showing this session's output
    if active_output_buffers[session_id] then
      for buf, _ in pairs(active_output_buffers[session_id]) do
        if vim.api.nvim_buf_is_valid(buf) then
          vim.schedule(function()
            vim.bo[buf].modifiable = true
            local current_lines = vim.api.nvim_buf_line_count(buf)
            vim.api.nvim_buf_set_lines(buf, current_lines, -1, false, lines)
            vim.bo[buf].modifiable = false

            -- Auto-scroll to bottom if window is visible
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_buf(win) == buf then
                local last_line = vim.api.nvim_buf_line_count(buf)
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
    }
  end

  -- Capture process ID when process event is received
  dap.listeners.after.event_process["store_pid"] = function(session, body)
    if body.systemProcessId then
      session_pids[session.id] = body.systemProcessId
    end
  end


  -- AI: also maybe subscribe to event of dap when killed 
  -- (some optimized behaviour especially for daps which emit this kind of events?)
  -- but timers shall remain, dont remove idea with periodic checks

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
  end

  -- Mark session as ended
  dap.listeners.before.event_terminated["mark_ended"] = session_terminated
  dap.listeners.before.event_exited["mark_ended"] = session_terminated

  -- Start periodic process checking every 2 seconds
  if not process_check_timer then
    process_check_timer = vim.uv.new_timer()

    if process_check_timer == nil then
      -- AI: give here warning using vim standard tools that timer cannot be created
    else
      process_check_timer:start(2000, 2000, vim.schedule_wrap(check_all_processes))
    end
  end

  -- Start periodic session synchronization every 5 seconds
  if not session_sync_timer then
    session_sync_timer = vim.uv.new_timer()
    if session_sync_timer == nil then
      -- AI: give here warning using vim standard tools that timer cannot be created
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

  -- Mark sessions as inactive if they no longer exist in DAP
  for session_id, meta in pairs(session_metadata) do
    if meta.active and not actual_session_ids[session_id] then
      meta.active = false
      meta.ended_at = os.date "%Y-%m-%d %H:%M:%S"
      session_pids[session_id] = nil
    end
  end
end

--- Show DAP output for current or selected session
function M.show_output()
  local dap = require "dap"
  local session = dap.session()

  local total_sessions = vim.tbl_count(session_metadata)

  -- If more than 1 session ever existed, always show picker
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
function M.show_session_picker(action)
  show_session_picker(action)
end

function M.get_active_sessions_count()
  local count = 0
  for _, meta in pairs(session_metadata) do
    if meta.active then
      count = count + 1
    end
  end
  return count
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
  return {
    function()
      local dap = require "dap"
      local session = dap.session()

      if not session then
        return ""
      end

      local meta = session_metadata[session.id]
      if not meta then
        return "DAP"
      end

      -- Check actual process status if we have PID
      local status_icon = "○" -- Default to inactive
      if meta.active then
        local pid = session_pids[session.id]
        if pid then
          -- If we have a PID, check actual process status
          if check_process_running(pid) then
            status_icon = "●" -- Actually running
          else
            status_icon = "○" -- Process dead but marked as active
          end
        else
          status_icon = "●" -- No PID but marked as active
        end
      else
        status_icon = "○" -- Explicitly marked as inactive
      end

      local name = meta.name or "DAP"
      local active_count = M.get_active_sessions_count()

      if active_count > 1 then
        return string.format("%s %s (%d)", status_icon, name, active_count)
      else
        return string.format("%s %s", status_icon, name)
      end
    end,
    cond = function()
      local ok, dap = pcall(require, "dap")
      if not ok then
        return false
      end
      return vim.tbl_count(dap.sessions()) > 0
    end,
  }
end

return M
