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
  hl(0, "NeogitDiffContextCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitDiffAddCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitDiffDeleteCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })
  hl(0, "NeogitDiffHeaderCursor", { bg = neogit_cursor_bg, fg = neogit_cursor_fg })

  local comment_fg = vim.api.nvim_get_hl(0, { name = "Comment" }).fg
  hl(0, "GitSignsCurrentLineBlame", { fg = comment_fg, italic = true })

  local palette = {
    insert = vim.api.nvim_get_hl(0, { name = "lualine_a_insert" }),
    -- foreground = "White",
    normal = vim.api.nvim_get_hl(0, { name = "lualine_a_normal" }),
    replace = vim.api.nvim_get_hl(0, { name = "lualine_a_replace" }),
    visual = vim.api.nvim_get_hl(0, { name = "lualine_a_visual" }),
  }
  require("line-number-change-mode").setup {
    mode = {
      i = palette.insert,
      n = palette.normal,
      R = palette.replace,
      v = palette.visual,
      V = palette.visual,
    },
  }
end

vim.api.nvim_create_autocmd({ "ColorScheme", "UIEnter" }, {
  pattern = "*",
  callback = override_highlights,
})

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "ErrorMsg", linehl = "Substitute", numhl = "Substitute" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "WarningMsg", linehl = "", numhl = "" })
