local hl = vim.api.nvim_set_hl

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

  hl(0, "SpellRare", {})
  hl(0, "SpellCap", {})
  hl(0, "SpellLocal", {})
end

vim.api.nvim_create_autocmd({ "ColorScheme", "UIEnter" }, {
  pattern = "*",
  callback = override_highlights,
})

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "ErrorMsg", linehl = "Substitute", numhl = "Substitute" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "WarningMsg", linehl = "", numhl = "" })
