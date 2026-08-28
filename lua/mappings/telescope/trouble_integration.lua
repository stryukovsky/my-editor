local trouble = require "trouble.sources.telescope"
local action_state = require "telescope.actions.state"
local close_trouble = require "utils.close_trouble"
local ui_prevent_mess = require "utils.ui_prevent_mess"

local function get_trouble_win()
  local trouble_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    if ft == "trouble" then
      trouble_win = win
      break
    end
  end
  return trouble_win
end

local function set_cursor_pos_in_trouble_win(index)
  local trouble_win = get_trouble_win()
  if not trouble_win or not vim.api.nvim_win_is_valid(trouble_win) then
    return false
  end

  local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(trouble_win))
  -- Window can exist with only a title while items are still rendering.
  if line_count < index then
    return false
  end

  vim.api.nvim_set_current_win(trouble_win)
  vim.api.nvim_win_set_cursor(trouble_win, { index, 0 })
  return true
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
      local index = 2 + picker:get_selection_row()
      if not close_trouble() then
        return
      end
      local sort_disabler = 0

      ui_prevent_mess()
      ---@diagnostic disable-next-line: missing-fields
      trouble.open(bufnr, {
        focus = false,
        mode = mode,
        follow = false,
        restore = false,
        sorters = {},
        sort = function(_)
          sort_disabler = sort_disabler + 1
          return sort_disabler
        end,
      })

      -- trouble.sources.telescope.open schedules the split; wait until the list
      -- actually contains the selected row, then pin the cursor again in case a
      -- late render moved it.
      vim.defer_fn(function()
        local success = vim.wait(4000, function()
          return set_cursor_pos_in_trouble_win(index)
        end, 50)
        if not success then
          vim.print "Cannot set cursor in trouble: seems really big stuff indexed"
          return
        end
        vim.defer_fn(function()
          set_cursor_pos_in_trouble_win(index)
        end, 200)
      end, 200)
    end
  end
end
