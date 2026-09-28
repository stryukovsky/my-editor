local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local function selection_path(selection)
  local path = selection.path or selection.filename or selection[1]
  if type(path) == "string" and selection.cwd and path:sub(1, 1) ~= "/" then
    path = selection.cwd .. "/" .. path
  end
  return path
end

local function selection_cursor(selection)
  if not selection.lnum then
    return nil
  end
  local col = selection.col and math.max(selection.col - 1, 0) or 0
  return { selection.lnum, col }
end

local function after_reveal(state, path, cursor)
  vim.defer_fn(function()
    local current = state
    if not current then
      current = require("neo-tree.sources.manager").get_state "filesystem"
    end
    if not current or not current.tree then
      return
    end
    if vim.fn.isdirectory(path) == 1 then
      require("utils.neotree_utils").go_deep(current)
      return
    end
    -- open_file uses :e in a non-tree window, so neo-tree stays open.
    require("neo-tree.utils").open_file(current, path, "edit")
    if cursor then
      pcall(vim.api.nvim_win_set_cursor, 0, cursor)
    end
  end, 50)
end

local function reveal_in_neotree(state, path, cursor)
  if state then
    require("neo-tree.sources.filesystem").navigate(state, state.path, path, function()
      after_reveal(state, path, cursor)
    end)
    return
  end
  require("neo-tree.command").execute {
    action = "reveal",
    source = "filesystem",
    reveal_file = path,
    reveal_force_cwd = true,
  }
  after_reveal(nil, path, cursor)
end

local function select(state)
  return function(prompt_bufnr)
    local actions = require "telescope.actions"
    local action_state = require "telescope.actions.state"
    local selection = action_state.get_selected_entry()
    if not selection then
      return
    end

    local path = selection_path(selection)
    if type(path) ~= "string" or path == "" then
      return
    end
    path = vim.fn.fnamemodify(path, ":p"):gsub("/$", "")

    actions.close(prompt_bufnr)
    vim.schedule(function()
      reveal_in_neotree(state, path, selection_cursor(selection))
    end)
  end
end

return function(state)
  local action = wrap_telescope_action(select(state))
  return {
    n = { ["<cr>"] = action },
    i = { ["<cr>"] = action },
  }
end
