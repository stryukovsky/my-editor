local M = {}

local function contains(root, path)
  root = vim.fs.normalize(root):gsub("/+$", "")
  path = vim.fs.normalize(path):gsub("/+$", "")
  return root == path or path:sub(1, #root + 1) == root .. "/"
end

local function connected_clients(path)
  local clients = {}
  for _, client in ipairs(vim.lsp.get_clients()) do
    local connected = false
    if client.initialized and not client:is_stopped() then
      local root = client.root_dir or client.config.root_dir
      connected = type(root) == "string" and contains(root, path)
      for _, folder in ipairs(client.workspace_folders or {}) do
        connected = connected or contains(vim.uri_to_fname(folder.uri), path)
      end
      for bufnr in pairs(client.attached_buffers or {}) do
        local name = vim.api.nvim_buf_is_valid(bufnr)
            and vim.api.nvim_buf_get_name(bufnr)
          or ""
        connected = connected or (name ~= "" and contains(path, name))
      end
    end
    if connected then
      clients[#clients + 1] = client
    end
  end
  table.sort(clients, function(a, b)
    return a.name == b.name and a.id < b.id or a.name < b.name
  end)
  return clients
end

local function rename(state, clients)
  local node = state.tree:get_node()
  local lsp_rename = require "neo-tree.sources.filesystem.lib.lsp_rename"
  local recipients, warnings = {}, {}
  if #clients == 0 then
    warnings[#warnings + 1] = "No connected LSP can update references."
  else
    for _, client in ipairs(clients) do
      local methods = lsp_rename.methods(client, node.path)
      local advertised = lsp_rename.methods(client)
      if methods.willRename or methods.didRename then
        recipients[#recipients + 1] = client
      elseif advertised.willRename or advertised.didRename then
        warnings[#warnings + 1] = client.name
          .. ": file rename is not supported for this path."
      else
        warnings[#warnings + 1] = client.name
          .. ": this LSP does not support file rename."
      end
    end
  end
  if #warnings > 0 then
    local message = table.concat(warnings, "\n")
      .. "\nReferences may not be updated. Proceed with filesystem rename?"
    if vim.fn.confirm(message, "&Yes\n&No", 2) ~= 1 then
      return
    end
  end
  local hooks
  if #recipients > 0 then
    hooks = lsp_rename.hooks(recipients)
  end
  require("neo-tree.sources.filesystem.commands").rename(state, hooks)
end

local function select_clients(clients, callback)
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  require("telescope.pickers")
    .new({}, {
      prompt_title = "Rename: LSP recipients (Tab to select, Enter to confirm)",
      finder = require("telescope.finders").new_table {
        results = clients,
        entry_maker = function(client)
          local operations = require(
            "neo-tree.sources.filesystem.lib.lsp_rename"
          ).methods(client)
          local methods = {}
          if operations.willRename then
            methods[#methods + 1] = "willRename"
          end
          if operations.didRename then
            methods[#methods + 1] = "didRename"
          end
          local label = ("%s [%d] — %s"):format(
            client.name,
            client.id,
            #methods > 0 and table.concat(methods, ", ")
              or "no file-rename methods"
          )
          return { value = client, display = label, ordinal = label }
        end,
      },
      sorter = require("telescope.config").values.generic_sorter {},
      attach_mappings = function(bufnr)
        actions.select_default:replace(function()
          local selected =
            action_state.get_current_picker(bufnr):get_multi_selection()
          if #selected == 0 then
            local current = action_state.get_selected_entry()
            if not current then
              return
            end
            selected = { current }
          end
          local recipients = {}
          for _, entry in ipairs(selected) do
            recipients[#recipients + 1] = entry.value
          end
          actions.close(bufnr)
          -- Restore Neo-tree's window before opening its rename prompt.
          vim.schedule(function()
            callback(recipients)
          end)
        end)
        return true
      end,
    })
    :find()
end

function M.rename(state)
  local node = state.tree:get_node()
  if not node or node.type == "message" or not node.path then
    return
  end
  local clients = connected_clients(node.path)
  if #clients < 2 then
    rename(state, clients)
    return
  end
  local source = node.path
  select_clients(clients, function(selected)
    -- A closed/replaced tree must not rename a different selection.
    if not state.bufnr or not vim.api.nvim_buf_is_valid(state.bufnr) then
      return
    end
    local current = state.tree and state.tree:get_node()
    if current and current.path == source then
      rename(state, selected)
    end
  end)
end

return M
