local map = require "mappings.map"
local notify = require "configs.notify"

---Cursor, scroll, and folds for every window showing this buffer.
---@param buf integer
---@return table<integer, table>
local function save_views(buf)
  local views = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == buf then
      views[win] = vim.api.nvim_win_call(win, vim.fn.winsaveview)
    end
  end
  return views
end

---@param views table<integer, table>
local function restore_views(views)
  for win, view in pairs(views) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_call(win, function()
        vim.fn.winrestview(view)
      end)
    end
  end
end

---Re-read the current Neo-tree source, keeping its expanded nodes and cursor.
local function refresh_neotree()
  local manager = require "neo-tree.sources.manager"
  local state = manager.get_state_for_window()
  if not state then
    notify.send(
      "Buffer",
      "Neo-tree has no state to refresh",
      vim.log.levels.WARN
    )
    return
  end
  manager.refresh(state.name)
end

---Re-read the file from disk. Unsaved edits stay in the buffer.
---@param buf integer
local function refresh_file(buf)
  if vim.bo[buf].modified then
    notify.send("Buffer", "Unsaved changes", vim.log.levels.WARN)
    return
  end

  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    notify.send("Buffer", "Nothing to refresh", vim.log.levels.INFO)
    return
  end

  local views = save_views(buf)
  local ok, err = pcall(vim.cmd.edit)
  if not ok then
    notify.send(
      "Buffer",
      tostring(err):gsub("^Vim:E%d+: ", ""),
      vim.log.levels.ERROR
    )
    return
  end
  restore_views(views)
end

local function refresh_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local filetype = vim.bo[buf].filetype
  if filetype == "neo-tree" then
    refresh_neotree()
    return
  end
  if filetype == "oil" then
    require("oil.actions").refresh.callback()
    return
  end

  local buftype = vim.bo[buf].buftype
  if
    buftype == ""
    or buftype == "help"
    or buftype == "acwrite"
    or buftype == "nowrite"
  then
    refresh_file(buf)
    return
  end

  notify.send("Buffer", "Nothing to refresh", vim.log.levels.INFO)
end

map("n", "<leader>rr", refresh_buffer, { desc = "Refresh buffer" })
