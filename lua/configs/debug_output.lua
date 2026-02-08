-- Store output per session
local session_outputs = {}
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

-- Function to display output in a buffer
return function()
  local session = dap.session()
  if not session then
    vim.notify("No active DAP session", vim.log.levels.WARN)
    return
  end

  local outputs = session_outputs[session.id]
  if not outputs or #outputs == 0 then
    vim.notify("No output for current session", vim.log.levels.INFO)
    return
  end

  -- Create or reuse buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "dap-output"

  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, outputs)

  -- Open in split window
  vim.cmd "split"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_name(buf, "DAP Output")

  -- Make buffer read-only
  vim.bo[buf].modifiable = false
end
