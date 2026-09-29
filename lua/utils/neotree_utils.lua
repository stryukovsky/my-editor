local filesystem = require "neo-tree.sources.filesystem"
local cmds = require "neo-tree.sources.filesystem.commands"
local renderer = require "neo-tree.ui.renderer"

local M = {}

function M.go_deep(state)
  local node = state.tree:get_node()
  if node.type ~= "directory" then
    cmds.open(state)
    return
  end

  local function focus_first_child()
    local children = node:get_child_ids()
    if #children == 0 then
      return
    end

    renderer.focus_node(state, children[1])
    if #children == 1 and state.tree:get_node().type == "directory" then
      M.go_deep(state)
    end
  end

  if node:is_expanded() then
    focus_first_child()
  else
    filesystem.toggle_directory(state, node, nil, nil, nil, focus_first_child)
  end
end

return M
