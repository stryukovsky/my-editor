local trouble_source = require "trouble.sources.telescope"
local trouble_api = require "trouble"
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local close_trouble_succeeded = require "moonshine.utils.close_trouble_succeeded"
local ui_prevent_mess = require "moonshine.utils.ui_prevent_mess"

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
---@return integer? win, integer? buf
local function edit_selection(selection)
  local filename, line, col = selection_location(selection)
  if not filename then
    return nil
  end

  -- Neo-tree redirects :edit asynchronously and restores its own buffer first.
  -- Open in an editor directly so both the buffer and cursor belong to it.
  if vim.bo.filetype == "neo-tree" then
    local editor
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "" and vim.api.nvim_win_get_config(win).relative == "" then
        editor = win
        break
      end
    end
    if editor then
      vim.api.nvim_set_current_win(editor)
    else
      vim.cmd "botright vnew"
    end
  end

  local ok = pcall(vim.cmd.edit, vim.fn.fnameescape(filename))
  if not ok then
    return nil
  end
  pcall(vim.api.nvim_win_set_cursor, 0, { line, col })
  return vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
end

local function collect_telescope_items(picker)
  local items = {}
  if #picker:get_multi_selection() > 0 then
    for _, item in ipairs(picker:get_multi_selection()) do
      table.insert(items, trouble_source.item(item))
    end
  else
    for item in picker.manager:iter() do
      table.insert(items, trouble_source.item(item))
    end
  end
  return items
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
      local items = collect_telescope_items(picker)
      local grep = mode == "ripgrep_results" and require "integrations.trouble.sources.ripgrep_results"
      local pattern = grep and action_state.get_current_line()
      local query = grep and picker:_get_prompt()
      if grep then
        grep.items = items
      else
        trouble_source.items = items
      end
      local wanted = trouble_source.item(selection)
      local _, selected_line, selected_col = selection_location(selection)

      ui_prevent_mess()
      actions.close(bufnr)
      local edit_win, edit_buf = edit_selection(selection)
      if not edit_win then
        return
      end

      local sort_disabler = 0
      ---@diagnostic disable-next-line: missing-fields
      local view = trouble_api.open {
        focus = false,
        mode = mode,
        new = grep ~= false,
        max_items = grep and #items or nil,
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
          -- Opening the results layout can restore a window's previous view.
          -- Apply the match after that work, to the captured editor only.
          vim.schedule(function()
            if vim.api.nvim_win_is_valid(edit_win) and vim.api.nvim_win_get_buf(edit_win) == edit_buf then
              local line = math.max(1, math.min(selected_line, vim.api.nvim_buf_line_count(edit_buf)))
              local col = math.max(0, selected_col)
              vim.api.nvim_win_set_cursor(edit_win, { line, col })
              vim.api.nvim_win_call(edit_win, function()
                vim.cmd "normal! zv"
              end)
            end
          end)
          if grep then
            grep.attach(view, pattern, query)
          end
        end)
      end
    end
  end
end
