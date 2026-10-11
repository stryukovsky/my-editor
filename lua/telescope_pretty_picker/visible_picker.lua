-- Jump among rows already shown in Neo-tree (expanded folders and their files).
-- <cr> expands a collapsed folder, or moves the cursor onto a file.

local notify = require "configs.notify"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local DIR_ICON = ""
local DIR_HL = "NeoTreeDirectoryIcon"

---@param root string
---@param path string
---@return string
local function relative_path(root, path)
  root = vim.fs.normalize(root):gsub("/+$", "")
  path = vim.fs.normalize(path):gsub("/+$", "")
  if root == "" or path == root then
    return vim.fs.basename(path)
  end
  local relative = vim.fs.relpath(root, path)
  if not relative or relative == "" then
    return vim.fs.basename(path)
  end
  return relative
end

---@param node table
---@return string, string
local function icon_for(node)
  if node.type == "directory" then
    return DIR_ICON, DIR_HL
  end
  local devicons = require "nvim-web-devicons"
  local icon, highlight = devicons.get_icon(node.name or "", node.ext, { default = true })
  return icon or "", highlight or "TelescopeResultsNormal"
end

---@param state table
---@return table[]
local function visible_items(state)
  local renderer = require "neo-tree.ui.renderer"
  local root = state.path or ""
  local items = {}
  for _, node in ipairs(renderer.get_all_visible_nodes(state.tree)) do
    local id = node:get_id()
    local shown = not node.skip_node and (node.type == "file" or node.type == "directory")
    if shown and type(id) == "string" and id ~= "" then
      local relative = relative_path(root, id)
      local parent = vim.fs.dirname(relative)
      if parent == "." then
        parent = ""
      end
      table.insert(items, {
        id = id,
        path = vim.fs.normalize(id),
        name = node.name or vim.fs.basename(id),
        ext = node.ext,
        type = node.type,
        parent = parent,
        relative = relative,
      })
    end
  end
  return items
end

---@param item table
---@return string, table
local function render_item(item)
  local icon, icon_hl = icon_for(item)
  local name = item.name
  if item.type == "directory" then
    name = name .. "/"
  end
  local text = icon .. " " .. name
  local highlights = { { { 0, #icon }, icon_hl } }
  if item.parent ~= "" then
    local gap = "  "
    local parent_start = #text + #gap
    text = text .. gap .. item.parent
    table.insert(highlights, { { parent_start, #text }, "TelescopeResultsComment" })
  end
  return text, highlights
end

---@param state table
---@param id string
local function focus_node(state, id)
  local renderer = require "neo-tree.ui.renderer"
  if renderer.focus_node(state, id) then
    return
  end
  -- group_empty_dirs can replace a folder node with a deeper id.
  -- The shortest remaining id under that folder is the grouped directory.
  local fallback
  local prefix = id:gsub("/+$", "") .. "/"
  for _, node in ipairs(renderer.get_all_visible_nodes(state.tree)) do
    local node_id = node:get_id()
    if type(node_id) == "string" and node_id:sub(1, #prefix) == prefix then
      if not fallback or #node_id < #fallback then
        fallback = node_id
      end
    end
  end
  if fallback then
    renderer.focus_node(state, fallback)
  end
end

---@param state table
local function open_or_focus(state)
  return function(prompt_bufnr)
    local actions = require "telescope.actions"
    local action_state = require "telescope.actions.state"
    local selection = action_state.get_selected_entry()
    if not selection or type(selection.id) ~= "string" then
      return
    end
    local id = selection.id
    actions.close(prompt_bufnr)
    vim.schedule(function()
      if not state.tree then
        return
      end
      local node = state.tree:get_node(id)
      if node and node.type == "directory" and not node:is_expanded() then
        local loaded = node.loaded ~= false
        require("neo-tree.sources.filesystem").toggle_directory(state, node, id, nil, nil, function()
          focus_node(state, id)
        end)
        if loaded then
          focus_node(state, id)
        end
        return
      end
      focus_node(state, id)
    end)
  end
end

---@param state table
local function previewer(state)
  local previewers = require "telescope.previewers"
  local conf = require("telescope.config").values
  return previewers.new_buffer_previewer {
    title = "Preview",
    get_buffer_by_name = function(_, entry)
      return entry.path
    end,
    define_preview = function(self, entry)
      if entry.type == "directory" then
        local lines = {}
        local node = state.tree and state.tree:get_node(entry.id)
        if node and node:is_expanded() and node:has_children() then
          for _, child in ipairs(state.tree:get_nodes(node:get_id())) do
            if not child.skip_node and (child.type == "file" or child.type == "directory") then
              local suffix = child.type == "directory" and "/" or ""
              table.insert(lines, (child.name or "") .. suffix)
            end
          end
        end
        if #lines == 0 then
          lines = { entry.relative .. "/" }
        end
        vim.bo[self.state.bufnr].filetype = ""
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        return
      end
      conf.buffer_previewer_maker(entry.path, self.state.bufnr, {
        bufname = self.state.bufname,
        winid = self.state.winid,
      })
    end,
  }
end

---@param opts? { state?: table }
local function visible_picker(opts)
  opts = opts or {}
  local state = opts.state
  if not state or not state.tree then
    notify.send("Neo-tree", "Open the file tree before navigating", vim.log.levels.WARN)
    return
  end

  local items = visible_items(state)
  if #items == 0 then
    notify.send("Neo-tree", "Nothing visible to jump to", vim.log.levels.WARN)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values

  require "utils.ui_prevent_mess"()
  local action = wrap_telescope_action(open_or_focus(state))

  pickers
    .new({}, {
      prompt_title = "Navigate",
      results_title = "Visible",
      wrap_results = true,
      finder = finders.new_table {
        results = items,
        entry_maker = function(item)
          local text, highlights = render_item(item)
          return {
            value = item.relative,
            ordinal = item.name .. " " .. item.relative,
            display = function()
              return text, highlights
            end,
            id = item.id,
            path = item.path,
            filename = item.path,
            type = item.type,
            relative = item.relative,
          }
        end,
      },
      previewer = previewer(state),
      sorter = conf.file_sorter {},
      attach_mappings = function(_, map)
        map("n", "<cr>", action)
        map("i", "<cr>", action)
        return true
      end,
    })
    :find()
end

return visible_picker
