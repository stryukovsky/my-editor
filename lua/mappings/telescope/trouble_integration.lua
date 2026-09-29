local trouble_source = require "trouble.sources.telescope"
local trouble_api = require "trouble"
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local close_trouble_succeeded = require "utils.close_trouble_succeeded"
local ui_prevent_mess = require "utils.ui_prevent_mess"

---@return string|nil, integer, integer
local function selection_location(selection)
  local filename = selection.path or selection.filename or selection.value
  if selection.filename and selection.cwd and not selection.path then
    filename = selection.cwd .. "/" .. selection.filename
  end
  if type(filename) ~= "string" or filename == "" then
    return nil, 1, 0
  end

  local line, col = 1, 0
  if selection.pos then
    line = selection.pos[1] or 1
    col = selection.pos[2] or 0
  elseif selection.lnum then
    line = selection.lnum
    -- Telescope col is 1-based; nvim_win_set_cursor is (1,0)-indexed.
    col = selection.col and math.max(selection.col - 1, 0) or 0
  end
  return filename, line, col
end

-- No terminal check: if `:e` works, the window is a usable editor.
---@return boolean
local function edit_selection(selection)
  local filename, line, col = selection_location(selection)
  if not filename then
    return false
  end

  local ok = pcall(vim.cmd.edit, vim.fn.fnameescape(filename))
  if not ok then
    return false
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
  return true
end

local function collect_telescope_items(picker)
  trouble_source.items = {}
  if #picker:get_multi_selection() > 0 then
    for _, item in ipairs(picker:get_multi_selection()) do
      table.insert(trouble_source.items, trouble_source.item(item))
    end
  else
    for item in picker.manager:iter() do
      table.insert(trouble_source.items, trouble_source.item(item))
    end
  end
end

---@param item trouble.Item|nil
---@param wanted trouble.Item|nil
---@return boolean
local function same_item(item, wanted)
  if not item or not wanted then
    return false
  end
  if item.filename ~= wanted.filename then
    return false
  end
  local a, b = item.pos or { 1, 0 }, wanted.pos or { 1, 0 }
  return a[1] == b[1] and a[2] == b[2]
end

-- Set Trouble's current item via that window's cursor. Does not focus Trouble.
local function select_picker_item(view, wanted)
  if not view or not wanted then
    return
  end
  local win = view.win and view.win.win
  if not win or not vim.api.nvim_win_is_valid(win) then
    return
  end
  for row, loc in pairs(view.renderer._locations) do
    if loc.item and loc.first_line and same_item(loc.item, wanted) then
      vim.wo[win].cursorline = true
      vim.api.nvim_win_set_cursor(win, { row, 0 })
      return
    end
  end
end

-- this outer function is kinda builder, depending on mode of trouble items to be shown when telescope window is closed
return function(mode)
  -- this inner function is default telescope fn with bufnr arg for creating a telescope window
  return function(bufnr)
    local picker = action_state.get_current_picker(bufnr)
    if not picker then
      return
    end
    local selection = action_state.get_selected_entry()
    if not selection then
      return
    end
    local count = picker.manager:num_results()
    if count > 0 then
      if not close_trouble_succeeded() then
        return
      end
      collect_telescope_items(picker)
      local wanted = trouble_source.item(selection)

      ui_prevent_mess()
      actions.close(bufnr)
      if not edit_selection(selection) then
        return
      end

      local sort_disabler = 0
      ---@diagnostic disable-next-line: missing-fields
      local view = trouble_api.open {
        focus = false,
        mode = mode,
        follow = false,
        restore = false,
        sorters = {},
        sort = function(_)
          sort_disabler = sort_disabler + 1
          return sort_disabler
        end,
      }
      if view then
        view:wait(function()
          select_picker_item(view, wanted)
        end)
      end
    end
  end
end
