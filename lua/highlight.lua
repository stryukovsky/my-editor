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
    local fg = hl_data.fg or "NONE"
    vim.api.nvim_set_hl(0, "CursorLineNr", { bg = hl_data.bg, fg = fg, bold = true })
    vim.api.nvim_set_hl(0, "CursorLineSign", { bg = hl_data.bg, fg = fg })
    vim.api.nvim_set_hl(0, "CursorLineFold", { bg = hl_data.bg, fg = fg, bold = true })
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

  hl(0, "CsvViewHeaderLine", { bold = true })

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
  hl(0, "FoldColumn", { bg = background, fg = "#c49a2e" })
  hl(0, "NeoTreeNormal", { bg = background })
  hl(0, "NeoTreeEndOfBuffer", { bg = background })
  -- Render Markdown: warm paper surfaces matching material-lighter.
  hl(0, "RenderMarkdownH1Bg", { bg = "#e5d5a6" })
  hl(0, "RenderMarkdownH2Bg", { bg = "#eee4ce" })
  hl(0, "RenderMarkdownH3Bg", { bg = "#f3e7c9" })
  hl(0, "RenderMarkdownH4Bg", { bg = "#f7f1e3" })
  hl(0, "RenderMarkdownH5Bg", { bg = "#f7f1e3" })
  hl(0, "RenderMarkdownH6Bg", { bg = "#f7f1e3" })
  hl(0, "RenderMarkdownH1", { fg = "#765613", bold = true })
  hl(0, "RenderMarkdownH2", { fg = "#8c6a1b", bold = true })
  hl(0, "RenderMarkdownH3", { fg = "#a07a24", bold = true })
  hl(0, "RenderMarkdownH4", { fg = "#5d5140", bold = true })
  hl(0, "RenderMarkdownH5", { fg = "#5d5140", bold = true })
  hl(0, "RenderMarkdownH6", { fg = "#5d5140", bold = true })
  hl(0, "@markup.heading.1.markdown", { fg = "#765613", bold = true })
  hl(0, "@markup.heading.2.markdown", { fg = "#8c6a1b", bold = true })
  hl(0, "@markup.heading.3.markdown", { fg = "#a07a24", bold = true })
  hl(0, "@markup.heading.4.markdown", { fg = "#5d5140", bold = true })
  hl(0, "@markup.heading.5.markdown", { fg = "#5d5140", bold = true })
  hl(0, "@markup.heading.6.markdown", { fg = "#5d5140", bold = true })
  hl(0, "markdownH1", { fg = "#765613", bold = true })
  hl(0, "markdownH2", { fg = "#8c6a1b", bold = true })
  hl(0, "markdownH3", { fg = "#a07a24", bold = true })
  hl(0, "markdownH4", { fg = "#5d5140", bold = true })
  hl(0, "markdownH5", { fg = "#5d5140", bold = true })
  hl(0, "markdownH6", { fg = "#5d5140", bold = true })
  hl(0, "RenderMarkdownCode", { bg = "#fcf6e9", fg = "#5d5140" })
  hl(0, "RenderMarkdownCodeInline", { bg = "#eee4ce", fg = "#765613" })
  hl(0, "RenderMarkdownCodeBorder", { bg = "#fcf6e9", fg = "#d8c8aa" })
  hl(0, "RenderMarkdownCodeInfo", { bg = "#fcf6e9", fg = "#9b8a72" })
  hl(0, "RenderMarkdownCodeFallback", { bg = "#fcf6e9", fg = "#5d5140" })
  hl(0, "RenderMarkdownTableHead", { bg = "#e5d5a6", fg = "#765613", bold = true })
  hl(0, "RenderMarkdownTableRow", { bg = "#fcf6e9", fg = "#5d5140" })
  hl(0, "NormalFloat", { bg = background })
  hl(0, "NotifyBackground", { bg = background })

  hl(0, "MarkSignHL", { fg = "#bb0000" })

  hl(0, "CodeCompanionInlineDiffHint", { bg = background, fg = foreground_active })

  hl(0, "FlashLabelOverriden", { bg = background, fg = foreground_active })
  hl(0, "HlSearchLensNear", { link = "Title" })
  hl(0, "HlSearchLens", { link = "Comment" })
  require("configs.strict_grammar").apply_spellbad()

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

  -- local fgGitSignsChanges_dark = "#fff7e8"
  -- local fgGitSignsChanges_light = "#0042ff"
  --
  -- if vim.o.background == "light" then
  --   hl(0, "GitSignsAddInline", { bold = true, italic = true, underline = true, fg = fgGitSignsChanges_light })
  --   hl(0, "GitSignsChangeInline", { bold = true, italic = true, underline = true, fg = fgGitSignsChanges_light })
  --   hl(0, "GitSignsDeleteInline", { bold = true, italic = true, strikethrough = true, fg = fgGitSignsChanges_light })
  -- elseif vim.o.background == "dark" then
  --   hl(0, "GitSignsAddInline", { bold = true, italic = true, underline = true, fg = fgGitSignsChanges_dark })
  --   hl(0, "GitSignsChangeInline", { bold = true, italic = true, underline = true, fg = fgGitSignsChanges_dark })
  --   hl(0, "GitSignsDeleteInline", { bold = true, italic = true, strikethrough = true, fg = fgGitSignsChanges_dark })
  -- else
  --   hl(0, "GitSignsAddInline", { bold = true, italic = true, underline = true, fg = fgGitSignsChanges_dark })
  --   hl(0, "GitSignsChangeInline", { bold = true, italic = true, underline = true, fg = fgGitSignsChanges_dark })
  --   hl(0, "GitSignsDeleteInline", { bold = true, italic = true, strikethrough = true, fg = fgGitSignsChanges_dark })
  -- end

  hl(0, "Comment", { fg = "#9b8a72", italic = true })
  hl(0, "MiniDiffSignAdd", { link = "GitSignsAdd" })
  hl(0, "MiniDiffSignChange", { link = "GitSignsChange" })
  hl(0, "MiniDiffSignDelete", { link = "GitSignsDelete" })

  local function rgb_parts(color)
    return math.floor(color / 65536) % 256, math.floor(color / 256) % 256, color % 256
  end

  local function rgb_join(r, g, b)
    return math.floor(r) * 65536 + math.floor(g) * 256 + math.floor(b)
  end

  local function mix_rgb(from, toward, amount)
    local r1, g1, b1 = rgb_parts(from)
    local r2, g2, b2 = rgb_parts(toward)
    return rgb_join(r1 + (r2 - r1) * amount, g1 + (g2 - g1) * amount, b1 + (b2 - b1) * amount)
  end

  local function overlay_bg(src, mix_amount)
    local src_hl = vim.api.nvim_get_hl(0, { name = src, link = false })
    local fallback = src == "DiffDelete" and (vim.o.background == "light" and 0xe53935 or 0xf07178)
      or (vim.o.background == "light" and 0x91b859 or 0xc3e88d)
    local base = src_hl.bg
    if not base then
      base = type(background) == "number" and mix_rgb(background, fallback, 0.22) or fallback
    end
    if mix_amount then
      return { bg = mix_rgb(base, fallback, mix_amount) }
    end
    return { bg = base }
  end

  -- Line overlay: red/green backgrounds, no strikethrough. Word-diff is a darker mix.
  -- Change hunks reuse delete (old) + add (new).
  hl(0, "MiniDiffOverAdd", { link = "DiffAdd" })
  hl(0, "MiniDiffOverDelete", overlay_bg "DiffDelete")
  hl(0, "MiniDiffOverChange", overlay_bg("DiffDelete", 0.35))
  hl(0, "MiniDiffOverChangeBuf", overlay_bg("DiffAdd", 0.35))
  hl(0, "MiniDiffOverContext", { link = "MiniDiffOverDelete" })
  hl(0, "MiniDiffOverContextBuf", { link = "MiniDiffOverAdd" })

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
    if mode_key == "i" then
      -- Solid insert cursor: reverse is invisible on empty cells (e.g. empty vim.ui.input).
      local insert_hl = vim.api.nvim_get_hl(0, { name = "lualine_a_insert" })
      if insert_hl and insert_hl.bg then
        vim.api.nvim_set_hl(0, "CursorI", {
          bg = insert_hl.bg,
          fg = insert_hl.fg or background or "NONE",
          bold = true,
        })
      else
        vim.api.nvim_set_hl(0, "CursorI", {
          bg = foreground_active,
          fg = background,
          bold = true,
        })
      end
    elseif mode_key ~= "c" then
      vim.api.nvim_set_hl(0, "Cursor" .. mode_key:upper(), { reverse = true, bold = true })
    end
    local blink = (mode_key == "n" or mode_key == "t" or mode_key == "c") and "-blinkwait700-blinkoff400-blinkon250" or ""
    table.insert(cursor_parts, mode_key .. ":block-Cursor" .. mode_key:upper() .. blink)
  end
  vim.opt.guicursor = table.concat(cursor_parts, ",")

  -- for macros.lua
  hl(0, "MacroStartBadge", { bg = "#e06c75", fg = "#282c34", bold = true })
  hl(0, "MacroStartChar", { bg = "#e06c75", fg = "#282c34", bold = true })

  sync_cursorline_nr()

  local project_colors = {
    "#c678dd",
    "#e06c75",
    "#98c379",
    "#56b6c2",
    "#d19a66",
    "#61afef",
    "#e5c07b",
  }
  for i, color in ipairs(project_colors) do
    hl(0, "TodoProject" .. i, { fg = color, bold = true })
  end
  hl(0, "TodoPriorityA", { bg = "#e06c75", fg = "#fff7e8", bold = true })
  hl(0, "TodoPriorityB", { bg = "#d19a66", fg = "#fff7e8", bold = true })
  hl(0, "TodoPriorityC", { bg = "#98c379", fg = "#fff7e8", bold = true })
  hl(0, "TodoDoneTask", { strikethrough = true })
end

vim.api.nvim_create_autocmd({ "ColorScheme", "UIEnter" }, {
  pattern = "*",
  callback = function()
    override_highlights()
    -- material.nvim applies SpellBad in an async pass after ColorScheme.
    vim.schedule(override_highlights)
  end,
})

vim.api.nvim_create_autocmd("ModeChanged", {
  pattern = "*",
  callback = sync_cursorline_nr,
})

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "ErrorMsg", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "WarningMsg", linehl = "", numhl = "" })
