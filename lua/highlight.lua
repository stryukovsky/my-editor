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

  -- nvimtree
  hl(0, "NvimTreeExecFile", { link = "NvimTreeNormal" })
  hl(0, "NvimTreeImageFile", { link = "NvimTreeNormal" })
  hl(0, "NvimTreeSpecialFile", { link = "NvimTreeNormal" })
  hl(0, "NvimTreeSymlink", { link = "NvimTreeNormal" })
  hl(0, "NvimTreeGitDeletedIcon", { fg = "#ff4e33" })
  hl(0, "NvimTreeGitIgnoredIcon", { link = "Comment" })
  hl(0, "NvimTreeGitNewIcon", { fg = "#138808" })
  hl(0, "NvimTreeGitDirtyIcon", { link = "String" })
  hl(0, "NvimTreeGitRenamedIcon", { link = "String" })
  hl(0, "NvimTreeGitMergeIcon", { link = "String" })
  hl(0, "NvimTreeGitStagedIcon", { link = "String" })

  hl(0, "IlluminatedWordText", { underline = true })
  hl(0, "IlluminatedWordRead", { underline = true })
  hl(0, "IlluminatedWordWrite", { underline = true })

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

  hl(0, "StatusLine", { bg = background })
  --
  hl(0, "VertSplit", { bg = background, fg = foreground_inactive })
  hl(0, "NeoTreeNormal", { bg = background })
  hl(0, "NeoTreeEndOfBuffer", { bg = background })

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
