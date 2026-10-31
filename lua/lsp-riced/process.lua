local M = {}
local processes = {}
local installed = false

local function handles()
  local result = {}
  vim.uv.walk(function(handle)
    if handle:get_type() == "process" and not handle:is_closing() then
      result[handle] = true
    end
  end)
  return result
end

function M.setup()
  if installed then
    return
  end
  installed = true
  local start = vim.lsp.rpc.start
  vim.lsp.rpc.start = function(cmd, ...)
    local before = handles()
    local rpc = start(cmd, ...)
    local spawned = {}
    for handle in pairs(handles()) do
      if not before[handle] then
        spawned[#spawned + 1] = handle
      end
    end
    -- RPC startup is synchronous. Track only an unambiguous new process.
    if #spawned == 1 then
      local handle = spawned[1]
      processes[rpc] = {
        handle = handle,
        pid = handle:get_pid(),
        name = vim.fn.fnamemodify(cmd[1], ":t"),
        command = table.concat(cmd, " "),
      }
    end
    return rpc
  end
end

function M.running()
  for _, client in ipairs(vim.lsp.get_clients()) do
    local process = processes[client.rpc]
    if process then
      process.name = client.name
      process.root = client.config.root_dir
      process.client_id = client.id
    end
  end
  local result = {}
  for rpc, process in pairs(processes) do
    if process.handle:is_closing() or vim.uv.kill(process.pid, 0) ~= 0 then
      processes[rpc] = nil
    else
      result[#result + 1] = process
    end
  end
  table.sort(result, function(a, b)
    if a.name == b.name then
      return a.pid < b.pid
    end
    return a.name < b.name
  end)
  return result
end

function M.kill(process)
  -- The original live handle guards against accidentally targeting a recycled PID.
  if process.handle:is_closing() or process.handle:get_pid() ~= process.pid then
    vim.notify("LSP process has already exited", vim.log.levels.WARN)
    return
  end
  local ok, err = vim.uv.kill(process.pid, 9)
  if ok ~= 0 then
    vim.notify("Failed to kill LSP: " .. tostring(err), vim.log.levels.ERROR)
  else
    vim.notify(string.format("Killed %s · PID %d", process.name, process.pid))
  end
end

function M.picker()
  local actions = require "telescope.actions"
  local state = require "telescope.actions.state"
  local running = M.running()
  if #running == 0 then
    vim.notify "No tracked LSP processes running"
    return
  end
  require("telescope.pickers")
    .new({ initial_mode = "normal" }, {
      prompt_title = "Force kill LSP · SIGKILL",
      finder = require("telescope.finders").new_table {
        results = running,
        entry_maker = function(process)
          local label = string.format(
            "%s · PID %d · %s",
            process.name,
            process.pid,
            process.root or process.command
          )
          return { value = process, display = label, ordinal = label }
        end,
      },
      sorter = require("telescope.config").values.generic_sorter {},
      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt)
        actions.select_default:replace(function()
          local entry = state.get_selected_entry()
          actions.close(prompt)
          if entry then
            M.kill(entry.value)
          end
        end)
        return true
      end,
    })
    :find()
end

return M
