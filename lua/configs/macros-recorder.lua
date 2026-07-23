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

      -- 1. Highlight character (skip if cursor is at end of line)
      local line_len = vim.fn.strlen(vim.api.nvim_buf_get_lines(0, current_row, current_row + 1, false)[1] or "")
      if current_col + 1 <= line_len then
        hl_extmark_id = vim.api.nvim_buf_set_extmark(0, macro_ns, current_row, current_col, {
          end_col = current_col + 1,
          hl_group = "MacroStartChar",
        })
      end

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
-- default values
require("recorder").setup {
  -- Named registers where macros are saved (single lowercase letters only).
  -- The first register is the default register used as macro-slot after
  -- startup.
  slots = { "a", "b" },

  -- specify one of options:
  -- [static]   -> use static slots, this is default behaviour
  -- [rotate]   -> rotates through letters specified in slots[]
  dynamicSlots = "static",

  mapping = {
    startStopRecording = "<leader>q",
    playMacro = "Q",
    switchSlot = "<C-q>",
    editMacro = "cq",
    deleteAllMacros = "dq",
    yankMacro = "yq",
  },

  -- Clears all macros-slots on startup.
  clear = false,

  -- Log level used for non-critical notifications; mostly relevant for nvim-notify.
  -- (Note that by default, nvim-notify does not show the levels `trace` & `debug`.)
  -- logLevel = vim.log.levels.INFO, -- :help vim.log.levels

  -- If enabled, only essential notifications are sent.
  -- If you do not use a plugin like nvim-notify, set this to `true`
  -- to remove otherwise annoying messages.
  lessNotifications = true,

  -- Use nerdfont icons in the status bar components and keymap descriptions
  useNerdfontIcons = true,

  -- Performance optimizations for macros with high count. When `playMacro` is
  -- triggered with a count higher than the threshold, nvim-recorder
  -- temporarily changes changes some settings for the duration of the macro.
  performanceOpts = {
    countThreshold = 100,
    lazyredraw = true, -- enable lazyredraw (see `:h lazyredraw`)
    noSystemClipboard = true, -- remove `+`/`*` from clipboard option
    autocmdEventsIgnore = { -- temporarily ignore these autocmd events
      "TextChangedI",
      "TextChanged",
      "InsertLeave",
      "InsertEnter",
      "InsertCharPre",
    },
  },
}
