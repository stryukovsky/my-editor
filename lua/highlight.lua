local hl = vim.api.nvim_set_hl

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
hl(0, "NvimTreeGitDeletedIcon", { fg="#ff4e33" })
hl(0, "NvimTreeGitDirtyIcon", { link = "PreProc" })
hl(0, "NvimTreeGitIgnoredIcon", { link = "Comment" })
hl(0, "NvimTreeGitMergeIcon", { link = "PreProc" })
hl(0, "NvimTreeGitNewIcon", { fg="#138808" })
hl(0, "NvimTreeGitRenamedIcon", { link = "PreProc" })
hl(0, "NvimTreeGitStagedIcon", { link = "PreProc" })

-- spell highlight
hl(0, "SpellRare", {})
hl(0, "SpellCap", {})
hl(0, "SpellLocal", {})
