local trouble = require "trouble.sources.telescope"
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"
local close_trouble = require "utils.close_trouble"

local function is_terminal_buf(bufnr)
  return vim.bo[bufnr].buftype == "terminal"
end

local function get_non_terminal_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if not is_terminal_buf(buf) then
      return win
    end
  end
  return nil
end

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
  if trouble_win then
    vim.api.nvim_set_current_win(trouble_win)

    local line_count = vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(trouble_win))
    local safe_index = math.min(index, line_count)
    vim.api.nvim_win_set_cursor(trouble_win, { safe_index, 0 })
    return true
  else
    return false
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
    if count > 1 then
      close_trouble()
      local sort_disabler = 0

      ---@diagnostic disable-next-line: missing-fields
      trouble.open(bufnr, {
        focus = false,
        mode = mode,
        sorters = {},
        sort = function(_)
          sort_disabler = sort_disabler + 1
          return sort_disabler
        end,
      })

      local index = 2 + picker:get_selection_row()
      vim.defer_fn(function()
        local success = vim.wait(1000, function()
          return set_cursor_pos_in_trouble_win(index)
        end, 200)
        if not success then
          vim.print "Cannot set cursor in trouble: seems really big stuff indexed"
        end
      end, 100)
    else
      actions.select_default(bufnr)
      vim.defer_fn(function()
        local cur_win = vim.api.nvim_get_current_win()
        local cur_buf = vim.api.nvim_win_get_buf(cur_win)
        -- if we landed on a terminal, find a real window
        if is_terminal_buf(cur_buf) then
          local win = get_non_terminal_win()
          if win then
            vim.api.nvim_set_current_win(win)
          end
          return
        end
        if selection.lnum then
          local line_count = vim.api.nvim_buf_line_count(cur_buf)
          local safe_lnum = math.min(selection.lnum, line_count)
          local safe_col = selection.col or 0
          vim.api.nvim_win_set_cursor(cur_win, { safe_lnum, safe_col })
        end
      end, 800)
    end
  end
end
