dofile(vim.g.base46_cache .. "nvimtree")

local api = require "nvim-tree.api"

local git_add = function()
  local node = api.tree.get_node_under_cursor()
  local gs = node.git_status.file

  -- If the current node is a directory get children status
  if gs == nil then
    gs = (node.git_status.dir.direct ~= nil and node.git_status.dir.direct[1])
      or (node.git_status.dir.indirect ~= nil and node.git_status.dir.indirect[1])
  end

  -- If the file is untracked, unstaged or partially staged, we stage it
  if gs == "??" or gs == "MM" or gs == "AM" or gs == " M" then
    vim.cmd("silent !git add " .. node.absolute_path)

  -- If the file is staged, we unstage
  elseif gs == "M " or gs == "A " then
    vim.cmd("silent !git restore --staged " .. node.absolute_path)
  end

  api.tree.reload()
end

-- function for left to assign to keybindings
local lefty = function()
  local node_at_cursor = api.tree.get_node_under_cursor()
  -- if it's a node and it's open, close
  if node_at_cursor.nodes and node_at_cursor.open then
    api.node.open.edit()
    -- else left jumps up to parent
  else
    api.node.navigate.parent()
  end
end

local righty
-- function for right to assign to keybindings
righty = function()
  local node_at_cursor = api.tree.get_node_under_cursor()
  if node_at_cursor.type == "directory" then
    local nodes = node_at_cursor.nodes
    local nodes_count
    local cursor_movement
    if node_at_cursor.open then
      nodes_count = #nodes -- if already open then firstly read child nodes count
      api.node.open.edit() -- then close current node
      cursor_movement = false
    else
      api.node.open.edit() -- if closed then firstly open
      nodes_count = #nodes -- and then read count
      cursor_movement = true
    end
    -- vim.print("Current node is " .. node_at_cursor.type .. " And its nodes are ".. #node_at_cursor.nodes)
    -- vim.print(get_keys(node_at_cursor.nodes))
    if nodes_count == 1 then
      if cursor_movement then
        vim.cmd "normal! j"
      end
      righty()
    end
  end
end

local search_in_node = function()
  local node_at_cursor = api.tree.get_node_under_cursor()
  if node_at_cursor.nodes then
    vim.cmd("Telescope live_grep search_dirs=" .. node_at_cursor.absolute_path)
  end
end

local function open_in_os_explorer()
  local node_at_cursor = api.tree.get_node_under_cursor()
  local searched_node = node_at_cursor.absolute_path
  if not node_at_cursor.nodes then
    searched_node = vim.system({ "dirname", "--", node_at_cursor.absolute_path }):wait().stdout:gsub("%s+", "")
  end
  local sysname = vim.loop.os_uname().sysname
  if sysname == "Darwin" then
    vim.system { "open", searched_node }
  elseif sysname == "Linux" then
    vim.system { "nautilus", searched_node }
  else
    vim.print("Unknown platform " .. sysname)
  end
end

local function my_on_attach(bufnr)
  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- default mappings
  api.config.mappings.default_on_attach(bufnr)

  vim.keymap.set("n", "<Right>", righty, opts "go into")
  vim.keymap.set("n", "<Left>", lefty, opts "go out")

  -- custom mappings
  vim.keymap.set("n", "R", api.tree.change_root_to_parent, opts "root to parent of current")
  vim.keymap.set("n", "s", git_add, opts "git stage/unstage")
  vim.keymap.set("n", "s", git_add, opts "git stage/unstage")
  vim.keymap.set("n", "?", api.tree.toggle_help, opts "Help")
  vim.keymap.set("n", "f", search_in_node, opts "Search")
  vim.keymap.set("n", "r", api.fs.rename_full, opts "Rename")
  vim.keymap.set("n", "O", open_in_os_explorer, opts "Open in explorer")
  vim.keymap.set("n", "o", open_in_os_explorer, opts "Open in explorer")
  vim.keymap.set("n", "K", api.tree.toggle_git_clean_filter, opts "Git changes")

  api.events.subscribe(api.events.Event.FileCreated, function(file)
    vim.cmd("edit " .. vim.fn.fnameescape(file.fname))
  end)
end

return {
  filters = { dotfiles = false, custom = { "^.git$" } },
  disable_netrw = true,
  hijack_cursor = true,
  sync_root_with_cwd = true,
  update_focused_file = {
    enable = true,
    update_root = false,
  },
  view = {
    width = 40,
    preserve_window_proportions = true,
  },
  renderer = {
    root_folder_label = false,
    highlight_git = true,
    indent_markers = { enable = true },
    icons = {
      glyphs = {
        default = "󰈚",
        folder = {
          default = "",
          empty = "",
          empty_open = "",
          open = "",
          symlink = "",
        },
        git = {
          unmerged = "",
          unstaged = "*",
          untracked = "",
        },
      },
    },
  },
  on_attach = my_on_attach,
}
