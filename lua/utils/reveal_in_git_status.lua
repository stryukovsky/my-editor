-- Prefer the already visible Git status tree; leave normal explorer behavior to the caller.
return function(path)
  if not path or path == "" then
    return false
  end
  local manager = require "neo-tree.sources.manager"
  local renderer = require "neo-tree.ui.renderer"
  local state = manager.get_state "git_status"
  if not state.tree or not renderer.tree_is_visible(state) then
    return false
  end

  path = vim.fs.normalize(path)
  local staged
  local function find(nodes)
    for _, node in ipairs(nodes) do
      if node.path and vim.fs.normalize(node.path) == path and node.type ~= "directory" then
        if node.extra and node.extra.git_group == "unstaged" then
          return node
        end
        staged = node
      end
      local match = find(state.tree:get_nodes(node:get_id()))
      if match then
        return match
      end
    end
  end
  local node = find(state.tree:get_nodes()) or staged
  return node ~= nil and renderer.focus_node(state, node:get_id()) or false
end
