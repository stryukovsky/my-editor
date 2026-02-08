-- Store output per session
local session_outputs = {}
local session_metadata = {}
local active_output_buffers = {} -- Track buffers showing output
local active_output_windows = {} -- Track windows showing output by session_id
local dap = require "dap"

dap.defaults.fallback.on_output = function(session, event)
  -- Get or create session output storage
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
          -- Make buffer temporarily modifiable
          vim.bo[buf].modifiable = true

          -- Get current line count and append new lines
          local current_lines = vim.api.nvim_buf_line_count(buf)
          vim.api.nvim_buf_set_lines(buf, current_lines, -1, false, lines)

          -- Make buffer read-only again
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
        -- Clean up invalid buffer reference
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

local function session_terminated(session)
  if session_metadata[session.id] then
    session_metadata[session.id].active = false
    session_metadata[session.id].ended_at = os.date "%Y-%m-%d %H:%M:%S"
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

local function show_session_output(session_id)
  local outputs = session_outputs[session_id]
  if not outputs or #outputs == 0 then
    vim.notify("No output for this session", vim.log.levels.INFO)
    return
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
  vim.api.nvim_buf_set_name(buf, "DAP Output: " .. (meta and meta.name or session_id))

  -- Track this window
  active_output_windows[session_id] = win

  -- Clean up window tracking when window is closed
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    callback = function()
      if active_output_windows[session_id] == win then
        active_output_windows[session_id] = nil
      end
    end,
  })

  -- Add 'q' mapping to close the window
  vim.keymap.set("n", "q", function()
    vim.cmd "close"
  end, { buffer = buf, silent = true, desc = "Close DAP output window" })

  -- Make buffer read-only
  vim.bo[buf].modifiable = false

  -- Scroll to bottom
  vim.schedule(function()
    local last_line = vim.api.nvim_buf_line_count(buf)
    vim.api.nvim_win_set_cursor(win, { last_line, 0 })
  end)
end

-- Show telescope picker for session selection
local function show_telescope_picker()
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not has_telescope then
    vim.notify("Telescope not available", vim.log.levels.WARN)
    return
  end

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

  -- Sort: active first, then by start time
  table.sort(sessions, function(a, b)
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
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          show_session_output(selection.value.session_id)
        end)
        return true
      end,
    })
    :find()
end

-- Main function with window state checking
return function()
  local session = dap.session()

  -- Check if there's an active session with an open window
  if session then
    local session_id = session.id
    local win = active_output_windows[session_id]

    -- If window exists and is valid, focus it and do nothing
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      return
    end

    -- Window doesn't exist, create it
    show_session_output(session_id)
    return
  end

  -- No active session - check if any window is open
  local any_window_open = false
  for session_id, win in pairs(active_output_windows) do
    if vim.api.nvim_win_is_valid(win) then
      any_window_open = true
      -- Close the window
      vim.api.nvim_win_close(win, false)
      active_output_windows[session_id] = nil
    end
  end

  -- Show telescope picker
  show_telescope_picker()
end
