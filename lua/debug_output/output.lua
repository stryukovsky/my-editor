-- Scratch log buffers for one DAP session's stdout/stderr.

local map = require "mappings.map"
local ansi = require "debug_output.ansi"
local state = require "debug_output.state"

local M = {}

math.randomseed(os.time())

---@return string
local function random_3char()
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  local result = {}
  for _ = 1, 3 do
    local index = math.random(#chars)
    result[#result + 1] = chars:sub(index, index)
  end
  return table.concat(result)
end

---@param buf integer
---@return integer|nil win
function M.find_window_for_buffer(buf)
  if not vim.api.nvim_buf_is_valid(buf) then
    return nil
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
      return win
    end
  end
end

--- First still-valid output buffer for this session; drops stale handles.
---@param session_id integer
---@return integer|nil buf
function M.find_buffer_for_session(session_id)
  local buffers = state.active_output_buffers[session_id]
  if not buffers then
    return nil
  end
  for buf, _ in pairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      return buf
    end
    buffers[buf] = nil
  end
end

---@param session_id integer
---@return string[]
local function header_lines(session_id)
  local meta = state.session_metadata[session_id]
  if not meta then
    return {}
  end
  local header = {
    "=== DAP Session Output ===",
    "Name: " .. meta.name,
    "Command: " .. meta.command,
    "Type: " .. meta.type,
    "Started: " .. meta.started_at,
  }
  if meta.ended_at then
    header[#header + 1] = "Ended: " .. meta.ended_at
  end
  header[#header + 1] = "Status: " .. (meta.active and "Active" or "Ended")
  header[#header + 1] = ""
  header[#header + 1] = "--- Output ---"
  header[#header + 1] = ""
  return header
end

---@param session_id integer
---@param buf integer
local function register_buffer(session_id, buf)
  if not state.active_output_buffers[session_id] then
    state.active_output_buffers[session_id] = {}
  end
  state.active_output_buffers[session_id][buf] = true
  vim.api.nvim_create_autocmd("BufDelete", {
    buffer = buf,
    callback = function()
      local buffers = state.active_output_buffers[session_id]
      if buffers then
        buffers[buf] = nil
      end
    end,
  })
end

---@param buf integer
---@param session_id integer
local function name_output_buffer(buf, session_id)
  local meta = state.session_metadata[session_id]
  local base = "DAP Output: " .. (meta and meta.name or session_id)
  if not pcall(vim.api.nvim_buf_set_name, buf, base) then
    vim.api.nvim_buf_set_name(buf, base .. " " .. random_3char())
  end
end

--- Append captured lines to every open log for this session.
--- Windows whose cursor is already on the last line follow new output.
---@param session_id integer
---@param lines string[]
function M.append_to_buffers(session_id, lines)
  local buffers = state.active_output_buffers[session_id]
  if not buffers then
    return
  end
  for buf, _ in pairs(buffers) do
    if not vim.api.nvim_buf_is_valid(buf) then
      buffers[buf] = nil
    else
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

        vim.api.nvim_buf_set_lines(buf, current_lines, -1, false, vim.tbl_map(ansi.strip, lines))
        vim.bo[buf].modifiable = false

        local last_line = vim.api.nvim_buf_line_count(buf)
        for _, win in ipairs(wins_to_follow) do
          if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_cursor(win, { last_line, 0 })
          end
        end
      end)
    end
  end
end

--- nvim-dap `on_output` handler: store lines and push them to open logs.
---@param session DebugOutputDapSession
---@param event { output: string }
function M.capture(session, event)
  local session_id = session.id
  if not state.session_outputs[session_id] then
    state.session_outputs[session_id] = {}
  end
  local lines = vim.split(event.output, "\n", { plain = true })
  for _, line in ipairs(lines) do
    table.insert(state.session_outputs[session_id], ansi.strip(line))
  end
  M.append_to_buffers(session_id, lines)
end

--- Allow editing after the session ends (buffers stay open).
---@param session_id integer
function M.unlock_buffers(session_id)
  local buffers = state.active_output_buffers[session_id]
  if not buffers then
    return
  end
  for buf, _ in pairs(buffers) do
    if vim.api.nvim_buf_is_valid(buf) then
      vim.schedule(function()
        vim.bo[buf].modifiable = true
      end)
    end
  end
end

function M.close_open_windows()
  for _, buffers in pairs(state.active_output_buffers) do
    for buf, _ in pairs(buffers) do
      if vim.api.nvim_buf_is_valid(buf) then
        local win = M.find_window_for_buffer(buf)
        if win then
          vim.api.nvim_win_close(win, false)
        end
      end
    end
  end
end

--- Focus an existing log window or open a new split for this session.
---@param session_id integer
function M.show_session(session_id)
  local outputs = state.session_outputs[session_id] or {}

  local existing_buf = M.find_buffer_for_session(session_id)
  if existing_buf then
    local win = M.find_window_for_buffer(existing_buf)
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_current_win(win)
      return
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "log"

  local content = vim.list_extend(header_lines(session_id), vim.tbl_map(ansi.strip, outputs))
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  register_buffer(session_id, buf)

  vim.cmd "split"
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  name_output_buffer(buf, session_id)
  map("n", "q", function()
    vim.cmd "close"
  end, { buffer = buf, nowait = true, silent = true, desc = "Close DAP output window" })
  -- Keep DAP logs out of Barbar and scope.nvim's listed-buffer cache.
  vim.bo[buf].buflisted = false
  vim.bo[buf].modifiable = false

  vim.schedule(function()
    vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
  end)
end

return M
