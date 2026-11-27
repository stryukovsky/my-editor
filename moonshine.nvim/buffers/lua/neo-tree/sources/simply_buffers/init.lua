local M = {
  name = "simply_buffers",
  display_name = " 󰈚 Bufs ",
}

local renderer = require "neo-tree.ui.renderer"
local manager = require "neo-tree.sources.manager"
local events = require "neo-tree.events"
local utils = require "neo-tree.utils"
local buffers = require "moonshine.buffers"

function M.navigate(state, path, path_to_reveal, callback)
  state.path = path or vim.fn.getcwd()
  local nodes = {}
  for _, buf in ipairs(buffers.list()) do
    local path = vim.api.nvim_buf_get_name(buf)
    local name = path ~= "" and vim.fn.fnamemodify(path, ":~:.") or "[No Name]"
    if vim.bo[buf].buftype == "terminal" then
      name = vim.fn.fnamemodify(path, ":t")
    end
    nodes[#nodes + 1] = {
      id = tostring(buf),
      name = (buffers.is_pinned(buf) and " " or "") .. name,
      path = path,
      type = "file",
      extra = { bufnr = buf, plain_name = name },
    }
  end
  renderer.show_nodes(nodes, state)
  if path_to_reveal then
    renderer.focus_node(state, tostring(path_to_reveal), true)
  end
  if callback then
    vim.schedule(callback)
  end
end

function M.setup()
  for _, event in ipairs { events.VIM_BUFFER_ADDED, events.VIM_BUFFER_DELETED, events.VIM_BUFFER_ENTER } do
    manager.subscribe(M.name, {
      event = event,
      handler = function()
        local state = manager.get_state(M.name)
        if state and renderer.window_exists(state) then
          utils.debounce("simply_buffers_refresh", function()
            M.navigate(state, state.path)
          end, 100, utils.debounce_strategy.CALL_LAST_ONLY)
        end
      end,
    })
  end
end

return M
