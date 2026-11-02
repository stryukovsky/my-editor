-- Shared transition for the standard Git lists. Handlers never read a closed
-- prompt: both direct keys and menu choices receive the same captured context.
local actions = require "telescope.actions"
local state = require "telescope.actions.state"
local map = require "mappings.map"
local yank = require "mappings.telescope.yank"
local M = {}

function M.yank(context)
  yank.yank_entries(context.entries, { cwd = context.cwd })
  if not context.prompt_bufnr then
    context.reopen()
  end
end

function M.attach(prompt_bufnr, opts, open, tell, items)
  local function capture()
    local selection = state.get_selected_entry()
    if not selection then
      tell("Nothing currently selected", vim.log.levels.WARN)
      return
    end
    local picker = state.get_current_picker(prompt_bufnr)
    local multi = vim.list_slice(picker:get_multi_selection())
    local context = {
      selection = selection,
      entries = #multi > 0 and multi or { selection },
      cwd = picker.cwd,
      picker = picker,
      prompt_bufnr = prompt_bufnr,
    }
    local query = picker:_get_prompt()
    context.close = function()
      if context.prompt_bufnr then
        actions.close(context.prompt_bufnr)
        context.prompt_bufnr = nil
        context.picker = nil
      end
    end
    context.reopen = function()
      local restored = false
      local function restore(new_picker)
        if restored then
          return
        end
        restored = true
        local index = 0
        for entry in new_picker.manager:iter() do
          index = index + 1
          local row = new_picker:get_row(index)
          if entry.value == selection.value then
            new_picker:set_selection(row)
          end
          for _, selected in ipairs(multi) do
            if entry.value == selected.value then
              new_picker:add_selection(row)
            end
          end
        end
      end
      open(
        vim.tbl_extend("force", {}, opts, {
          cwd = context.cwd,
          default_text = query,
        }),
        restore
      )
    end
    return context
  end

  local function run(handler, context)
    local ok, err = xpcall(function()
      handler(context)
    end, debug.traceback)
    if not ok then
      -- Close only the originating list, never a later UI opened by a handler.
      if
        context.prompt_bufnr and vim.api.nvim_buf_is_valid(context.prompt_bufnr)
      then
        context.close()
      end
      tell(err, vim.log.levels.ERROR)
    end
  end

  actions.select_default:replace(function()
    local context = capture()
    if not context then
      return
    end
    context.close()
    vim.schedule(function()
      vim.ui.select(items, {
        prompt = "Actions: " .. context.selection.value,
        format_item = function(item)
          return item[1]
        end,
      }, function(item)
        if item then
          run(item[2], context)
        else
          context.reopen()
        end
      end)
    end)
  end)

  -- Install after Telescope's defaults with the RU/EN-aware map wrapper.
  vim.schedule(function()
    if not vim.api.nvim_buf_is_valid(prompt_bufnr) then
      return
    end
    for _, item in ipairs(items) do
      for _, key in ipairs(item.keys or {}) do
        map("n", key, function()
          local context = capture()
          if context then
            run(item[2], context)
          end
        end, { buffer = prompt_bufnr, desc = item[1] })
      end
    end
  end)
  return true
end

return M
