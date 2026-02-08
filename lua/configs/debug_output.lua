-- Store output per session
local session_outputs = {}
local session_metadata = {}
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

-- Mark session as ended
dap.listeners.before.event_terminated["mark_ended"] = function(session)
  if session_metadata[session.id] then
    session_metadata[session.id].active = false
    session_metadata[session.id].ended_at = os.date "%Y-%m-%d %H:%M:%S"
  end
end

dap.listeners.before.event_exited["mark_ended"] = function(session)
  if session_metadata[session.id] then
    session_metadata[session.id].active = false
    session_metadata[session.id].ended_at = os.date "%Y-%m-%d %H:%M:%S"
  end
end

-- Function to display output in a buffer
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
  vim.bo[buf].filetype = "dap-output"

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

  -- Open in split window
  vim.cmd "split"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_name(buf, "DAP Output: " .. (meta and meta.name or session_id))

  -- Make buffer read-only
  vim.bo[buf].modifiable = false
end

-- Main function with Telescope picker
return function()
  local session = dap.session()

  -- If there's an active session, show its output directly
  if session then
    show_session_output(session.id)
    return
  end

  -- No active session - show Telescope picker
  local has_telescope, pickers = pcall(require, "telescope.pickers")
  if not has_telescope then
    vim.notify("No active session and Telescope not available", vim.log.levels.WARN)
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
      display = string.format("[%s] %s - %s (%s)", "○", meta.name, meta.command, meta.started_at),
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
      initial_mode = "normal",
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
