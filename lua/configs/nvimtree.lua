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

-- function for right to assign to keybindings
local righty = function()
  local node_at_cursor = api.tree.get_node_under_cursor()
  -- if it's a closed node, open it
  if node_at_cursor.nodes and not node_at_cursor.open then
    api.node.open.edit()
  end
end

local search_in_node = function()
  local node_at_cursor = api.tree.get_node_under_cursor()
  if node_at_cursor.nodes and not node_at_cursor.open then
    vim.cmd("Telescope live_grep search_dirs=" .. node_at_cursor.absolute_path)
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
  vim.keymap.set("n", "?", api.tree.toggle_help, opts "Help")
  vim.keymap.set("n", "f", search_in_node, opts "Search")
  vim.keymap.set("n", "r", api.fs.rename_full, opts "Rename")

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
    width = 30,
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
        },
      },
    },
  },
  on_attach = my_on_attach,
}
