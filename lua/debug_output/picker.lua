-- Telescope picker over DAP sessions in the current tab.

local notify = require "configs.notify"
local process = require "debug_output.process"
local session = require "debug_output.session"
local state = require "debug_output.state"

local M = {}

---@class DebugOutputPickerOpts
--- Only sessions that are still a live debuggee.
---@field live_only? boolean
--- Toast "Switched to session: …" (default true).
---@field notify_switch? boolean

---@class DebugOutputPickerEntry
---@field session_id integer
---@field display string one picker line: `[icon] name - command (started)`
---@field meta DebugOutputSessionMeta

---@alias DebugOutputPickerAction fun(session_id: integer, meta: DebugOutputSessionMeta, dap_session: DebugOutputDapSession|nil)

---@param root DebugOutputDapSession
---@return DebugOutputPickerEntry
local function entry_from_root(root)
  local meta = session.meta_for(root)
    or {
      name = root.config and root.config.name or "DAP",
      command = root.config and (root.config.program or root.config.request) or "",
      started_at = "",
      active = true,
    }
  return {
    session_id = root.id,
    display = string.format("[%s] %s - %s (%s)", session.status_icon(root.id, root, meta), meta.name, meta.command, meta.started_at),
    meta = meta,
  }
end

---@param opts DebugOutputPickerOpts
---@return DebugOutputPickerEntry[]
local function collect_sessions(opts)
  local sessions = {}
  if opts.live_only then
    for _, root in pairs(session.live_roots_for_tab()) do
      sessions[#sessions + 1] = entry_from_root(root)
    end
    return sessions
  end
  for session_id, meta in pairs(session.metadata_for_tab()) do
    sessions[#sessions + 1] = {
      session_id = session_id,
      display = string.format("[%s] %s - %s (%s)", session.status_icon(session_id, nil, meta), meta.name, meta.command, meta.started_at),
      meta = meta,
    }
  end
  return sessions
end

--- Running first, then by `started_at` descending.
---@param sessions DebugOutputPickerEntry[]
local function sort_sessions(sessions)
  table.sort(sessions, function(a, b)
    local a_pid = state.session_pids[a.session_id]
    local b_pid = state.session_pids[b.session_id]
    if a_pid and b_pid then
      local a_running = process.is_running(a_pid)
      local b_running = process.is_running(b_pid)
      if a_running ~= b_running then
        return a_running
      end
    end
    if a.meta.active ~= b.meta.active then
      return a.meta.active
    end
    return a.meta.started_at > b.meta.started_at
  end)
end

--- Pick a session, switch DAP to it if it is live, then run `action`.
---@param action DebugOutputPickerAction
---@param opts? DebugOutputPickerOpts
function M.show(action, opts)
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

  local sessions = collect_sessions(opts)
  if #sessions == 0 then
    notify.send("Debug Output", "No DAP sessions found")
    return
  end
  sort_sessions(sessions)
  require("utils.ui_prevent_mess")()

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
          local dap_session = session.find_dap_session(session_id)
          if dap_session and session.is_live(dap_session) then
            dap.set_session(dap_session)
            if opts.notify_switch ~= false then
              notify.send("Debug Output", "Switched to session: " .. meta.name)
            end
          else
            dap_session = nil
          end
          if action then
            action(session_id, meta, dap_session)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
