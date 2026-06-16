local macro_group = vim.api.nvim_create_augroup("MacroVisualizerGroup", { clear = true })
local macro_ns = vim.api.nvim_create_namespace "macro_start_anchor"

local badge_extmark_id = nil
local hl_extmark_id = nil

-- Define colors

-- Function to completely wipe out old elements
local function clear_macro_markers()
  if hl_extmark_id then
    pcall(vim.api.nvim_buf_del_extmark, 0, macro_ns, hl_extmark_id)
    hl_extmark_id = nil
  end
  if badge_extmark_id then
    pcall(vim.api.nvim_buf_del_extmark, 0, macro_ns, badge_extmark_id)
    badge_extmark_id = nil
  end
  vim.api.nvim_buf_clear_namespace(0, macro_ns, 0, -1)
end

vim.api.nvim_create_autocmd("RecordingEnter", {
  group = macro_group,
  callback = function()
    clear_macro_markers()

    -- FIX: Unpack the table into separate row and col variables
    local cursor = vim.api.nvim_win_get_cursor(0)
    local current_row = cursor[1] - 1 -- API rows are 0-indexed
    local current_col = cursor[2]

    -- Schedule lets Neovim register the keystroke before we look up the letter
    vim.schedule(function()
      -- Fetch the active register (returns "f" if you typed qf)
      local register = vim.fn.reg_recording()
      if register == "" then
        register = "?"
      end

      -- 1. Highlight character
      hl_extmark_id = vim.api.nvim_buf_set_extmark(0, macro_ns, current_row, current_col, {
        end_col = current_col + 1,
        hl_group = "MacroStartChar",
      })

      -- 2. Drop the visual badge text helper WITH the register string
      badge_extmark_id = vim.api.nvim_buf_set_extmark(0, macro_ns, current_row, current_col, {
        virt_text = { { " ◀ Macro Start: @" .. register .. " ", "MacroStartBadge" } },
        virt_text_pos = "eol",
      })
    end)
  end,
})

vim.api.nvim_create_autocmd("RecordingLeave", {
  group = macro_group,
  callback = clear_macro_markers,
})
