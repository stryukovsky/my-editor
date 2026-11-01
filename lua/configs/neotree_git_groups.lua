-- Keep the staged/unstaged view in the config rather than the plugin checkout.
local M = {}

local function build(root, entries, group)
  local prefix = "git_status:" .. group .. ":"
  local section = {
    id = prefix .. root,
    path = root,
    name = group == "staged" and "Staged" or "Unstaged",
    type = "directory",
    loaded = true,
    children = {},
    extra = { git_group = group },
  }
  local directories = { [root] = section }
  local function directory(path)
    if directories[path] then
      return directories[path]
    end
    local parent = directory(vim.fs.dirname(path))
    local node = {
      id = prefix .. path,
      path = path,
      name = vim.fs.basename(path),
      type = "directory",
      loaded = true,
      children = {},
      extra = { git_group = group },
    }
    directories[path] = node
    parent.children[#parent.children + 1] = node
    return node
  end
  for _, entry in ipairs(entries) do
    local status = entry.status
    local conflict = require("neo-tree.git.parser").status_code_is_conflict(
      status:sub(1, 1),
      status:sub(2, 2)
    )
    local included = group == "staged"
        and not conflict
        and status:sub(1, 1) ~= "."
        and status ~= "??"
      or group == "unstaged" and (conflict or status:sub(2, 2) ~= ".")
    if included then
      local path = root .. "/" .. entry.path
      local parent = directory(vim.fs.dirname(path))
      parent.children[#parent.children + 1] = {
        id = prefix .. path,
        path = path,
        name = vim.fs.basename(path),
        type = "file",
        extra = {
          git_group = group,
          git_status = status,
          original_path = entry.original_path
              and root .. "/" .. entry.original_path
            or nil,
        },
      }
    end
  end
  return section, directories
end

function M.get_git_status(state)
  if state.loading then
    return
  end
  state.loading = true
  local ok, err = pcall(function()
    local git = require "configs.gitutils"
    local root, root_error = git.root(state.path)
    if not root then
      error(root_error)
    end
    local output, status_error = git.run(
      { "status", "--porcelain=v1", "-z", "--untracked-files=all" },
      root
    )
    if not output then
      error(status_error)
    end
    state.path = root
    local records = vim.split(output, "\0", { plain = true, trimempty = true })
    local entries, i = {}, 1
    while i <= #records do
      local record = records[i]
      local status = record:sub(1, 2):gsub(" ", ".")
      local entry = { status = status, path = record:sub(4) }
      if status:find "[RC]" then
        i = i + 1
        entry.original_path = records[i]
      end
      entries[#entries + 1] = entry
      i = i + 1
    end
    local nodes = {}
    state.default_expanded_nodes = {}
    for _, group in ipairs { "unstaged", "staged" } do
      local section, directories = build(root, entries, group)
      require("neo-tree.sources.common.file-items").advanced_sort(
        section.children,
        state
      )
      nodes[#nodes + 1] = section
      for _, node in pairs(directories) do
        state.default_expanded_nodes[#state.default_expanded_nodes + 1] =
          node.id
      end
    end
    require("neo-tree.ui.renderer").show_nodes(nodes, state)
  end)
  state.loading = false
  if not ok then
    require("neo-tree.log").error(err)
  end
end

function M.setup()
  require("neo-tree.sources.git_status.lib.items").get_git_status =
    M.get_git_status
end

return M
