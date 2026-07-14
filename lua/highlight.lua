local hl = vim.api.nvim_set_hl

local function sync_cursorline_nr()
  local mode_map = {
    n = "normal",
    i = "insert",
    v = "visual",
    V = "visual",
    ["\22"] = "visual",
    s = "visual",
    S = "visual",
    ["\19"] = "visual",
    r = "replace",
    R = "replace",
    c = "command",
    t = "terminal",
  }
  local mode_name = mode_map[vim.fn.mode()]
  if not mode_name then
    return
  end
  local hl_data = vim.api.nvim_get_hl(0, { name = "lualine_a_" .. mode_name })
  if hl_data and hl_data.bg then
    vim.api.nvim_set_hl(0, "CursorLineNr", { bg = hl_data.bg, fg = hl_data.fg or "NONE", bold = true })
  end
end

local function override_highlights()
  hl(0, "PreProc", { link = "Comment" })

  -- Customize how cursors look.
  hl(0, "MultiCursorCursor", { link = "Cursor" })
  hl(0, "MultiCursorVisual", { link = "Visual" })
  hl(0, "MultiCursorSign", { link = "SignColumn" })
  hl(0, "MultiCursorMatchPreview", { link = "Search" })
  hl(0, "MultiCursorDisabledCursor", { link = "Visual" })
  hl(0, "MultiCursorDisabledVisual", { link = "Visual" })
  hl(0, "MultiCursorDisabledSign", { link = "SignColumn" })

  hl(0, "IlluminatedWordText", { underline = true })
  hl(0, "IlluminatedWordRead", { underline = true })
  hl(0, "IlluminatedWordWrite", { underline = true })

  hl(0, "NeogitPopupConfigKey", { link = "Title" })
  hl(0, "NeogitPopupActionKey", { link = "Title" })
  hl(0, "NeogitPopupOptionKey", { link = "Title" })
  hl(0, "NeogitPopupSwitchKey", { link = "Title" })

  hl(0, "DiffViewFilePanelTitle", { link = "Title" })
  hl(0, "DiffViewFilePanelFileName", { link = "Normal" })

  local background = vim.api.nvim_get_hl(0, { name = "Normal" }).bg
  local foreground_inactive = vim.api.nvim_get_hl(0, { name = "Normal" }).fg
  local foreground_active = vim.api.nvim_get_hl(0, { name = "Title" }).fg
  hl(0, "NeoTreeTabInactive", { bg = background, fg = foreground_inactive })
  hl(0, "NeoTreeTabActive", { bg = background, fg = foreground_active })
  hl(0, "NeoTreeTabSeparatorInactive", { bg = background, fg = background })
  hl(0, "NeoTreeTabSeparatorActive", { bg = background, fg = background })

  local current_buffer_bg = vim.api.nvim_get_hl(0, { name = "BufferDefaultCurrent" }).bg
  local current_buffer_fg = vim.api.nvim_get_hl(0, { name = "BufferDefaultCurrent" }).fg
  hl(0, "BufferCurrentMod", { bold = true, background = current_buffer_bg, foreground = current_buffer_fg })
  local alternate_buffer_bg = vim.api.nvim_get_hl(0, { name = "BufferDefaultAlternate" }).bg
  hl(0, "BufferAlternateMod", { bold = true, background = alternate_buffer_bg })
  local inactive_buffer_bg = vim.api.nvim_get_hl(0, { name = "BufferDefaultInactive" }).bg
  hl(0, "BufferInactiveMod", { bold = true, background = inactive_buffer_bg })
  local visible_buffer_bg = vim.api.nvim_get_hl(0, { name = "BufferDefaultVisible" }).bg
  hl(0, "BufferVisibleMod", { bold = true, background = visible_buffer_bg })

  hl(0, "StatusLine", { bg = background })
  hl(0, "VertSplit", { bg = background, fg = foreground_inactive })
  hl(0, "NeoTreeNormal", { bg = background })
  hl(0, "NeoTreeEndOfBuffer", { bg = background })
  hl(0, "RenderMarkdownCode", { bg = background })
  hl(0, "NormalFloat", { bg = background })
  hl(0, "NotifyBackground", { bg = background })

  hl(0, "SpectreSearch", { fg = foreground_active })
  hl(0, "SpectreReplace", { link = "Added" })

  hl(0, "CodeCompanionInlineDiffHint", { bg = background, fg = foreground_active })

  hl(0, "FlashLabelOverriden", { bg = background, fg = foreground_active })

  hl(0, "SpellRare", {})
  hl(0, "SpellCap", {})
  hl(0, "SpellLocal", {})

  hl(0, "Cursor", { bg = foreground_active })
  hl(0, "NeogitDiffContext", { bg = background })
  -- move to default cursor
  local neogit_cursor_bg = vim.api.nvim_get_hl(0, { name = "NeogitCursor" }).bg
  local neogit_cursor_fg = vim.api.nvim_get_hl(0, { name = "NeogitCursor" }).fg
  hl(0, "NeogitHunkHeaderCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitBranchHead", { fg = foreground_active })
  hl(0, "NeogitDiffContextCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitDiffAddCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitDiffDeleteCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitDiffHeaderCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })

  local comment_fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg
  hl(0, "GitSignsCurrentLineBlame", { fg = comment_fg, italic = true })
  hl(0, "GitSignsAddInline", { bold = true, italic = true, underline = true, fg = "#0042ff" })
  hl(0, "GitSignsChangeInline", { bold = true, italic = true, underline = true, fg = "#0042ff" })
  hl(0, "GitSignsDeleteInline", { bold = true, italic = true, strikethrough = true, fg = "#0042ff" })

  local modes = {
    "n",
    "i",
    "v",
    "r",
    "c",
    "t",
  }

  local cursor_parts = {}
  for _, mode_key in ipairs(modes) do
    vim.api.nvim_set_hl(0, "Cursor" .. mode_key:upper(), { reverse = true, bold = true })
    local blink = (mode_key == "n" or mode_key == "t" or mode_key == "c") and "-blinkwait700-blinkoff400-blinkon250" or ""
    table.insert(cursor_parts, mode_key .. ":block-Cursor" .. mode_key:upper() .. blink)
  end
  vim.opt.guicursor = table.concat(cursor_parts, ",")

  -- for macros.lua
  vim.api.nvim_set_hl(0, "MacroStartBadge", { bg = "#e06c75", fg = "#282c34", bold = true })
  vim.api.nvim_set_hl(0, "MacroStartChar", { bg = "#e06c75", fg = "#282c34", bold = true })
  vim.api.nvim_set_hl(0, "CodeDiffCharInsert", { bg = "#0042ff", fg = "#282c34", underline = true })
  vim.api.nvim_set_hl(0, "CodeDiffCharDelete", { bg = "#0042ff", fg = "#282c34", underline = true })

  sync_cursorline_nr()
end

vim.api.nvim_create_autocmd({ "ColorScheme", "UIEnter" }, {
  pattern = "*",
  callback = override_highlights,
})

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = sync_cursorline_nr,
})

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "ErrorMsg", linehl = "Substitute", numhl = "Substitute" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "WarningMsg", linehl = "", numhl = "" })
