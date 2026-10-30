local map = require "mappings.map"
local repeat_navigation = require "utils.navigation_repeat"
local M = {}

local function navigate(state, direction, conflicts)
  if not state.tree or not state.winid or not vim.api.nvim_win_is_valid(state.winid) then
    return
  end
  local current = state.tree:get_node()
  if not current then
    return
  end
  local parser = require "neo-tree.git.parser"
  local renderer = require "neo-tree.ui.renderer"
  local function matches(status)
    if not status or status == "!" or status == "!!" then
      return false
    end
    return not conflicts or parser.status_code_is_conflict(status:sub(1, 1), status:sub(2, 2))
  end
  local ids, eligible = {}, {}
  local current_id = current:get_id()
  if state.name == "git_status" then
    local function visit(nodes)
      for _, node in ipairs(nodes) do
        local id = node:get_id()
        ids[#ids + 1] = id
        eligible[id] = node.type == "file" and matches(node.extra and node.extra.git_status)
        visit(state.tree:get_nodes(id))
      end
    end
    visit(state.tree:get_nodes())
  else
    local utils = require "neo-tree.utils"
    local _, worktree = require("neo-tree.git").find_existing_worktree(current_id)
    if not worktree then
      return
    end
    ids = { current_id }
    for path, status in pairs(worktree.status) do
      if utils.is_subpath(state.path, path) and matches(status) then
        local stat = vim.uv.fs_stat(path)
        if not stat or stat.type ~= "directory" then
          eligible[path] = true
          if path ~= current_id then
            ids[#ids + 1] = path
          end
        end
      end
    end
    ids = utils.sort_by_tree_display(ids)
  end
  local index = 1
  for i, id in ipairs(ids) do
    if id == current_id then
      index = i
      break
    end
  end
  for offset = 1, #ids do
    local target = ids[(index - 1 + direction * offset) % #ids + 1]
    if eligible[target] then
      if state.tree:get_node(target) then
        renderer.focus_node(state, target)
      else
        require("neo-tree.sources.filesystem").navigate(state, state.path, target, nil, false)
      end
      return
    end
  end
end

function M.attach(state)
  if (state.name ~= "filesystem" and state.name ~= "git_status")
    or not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
    return
  end
  for _, kind in ipairs({ { "g", false, "git change" }, { "x", true, "git conflict" } }) do
    local key, conflicts, name = unpack(kind)
    local function next_item()
      navigate(state, 1, conflicts)
    end
    local function previous_item()
      navigate(state, -1, conflicts)
    end
    for _, binding in ipairs({ { "]" .. key, next_item }, { "[" .. key, previous_item } }) do
      map("n", binding[1], function()
        repeat_navigation.set(next_item, previous_item, "Neo-tree " .. name)
        binding[2]()
      end, { buffer = state.bufnr, desc = "Neo-tree: " .. (binding[1]:sub(1, 1) == "]" and "next " or "previous ") .. name })
    end
  end
end

return M
