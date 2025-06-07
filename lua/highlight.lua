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

  hl(0, "LspSignatureActiveParameter", { force = true, fg = "#ff0000" })
  -- hl(0, "TelescopeSelection", {fg = "#ffffff", bg = "#000000", force = true})

  -- spell highlight
  hl(0, "SpellRare", {})
  hl(0, "SpellCap", {})
  hl(0, "SpellLocal", {})
end

vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = override_highlights,
})

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "ErrorMsg", linehl = "Substitute", numhl = "Substitute" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "WarningMsg", linehl = "", numhl = "" })

override_highlights()
