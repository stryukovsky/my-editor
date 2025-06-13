require("barbar").setup {
  tabpages = false,
  highlight_alternate = false,
  highlight_inactive_file_icons = false,
  highlight_visible = false,

  icons = {
    -- Configure the base icons on the bufferline.
    -- Valid options to display the buffer index and -number are `true`, 'superscript' and 'subscript'
    buffer_index = false,
    buffer_number = false,
    button = "",
    -- Enables / disables diagnostic symbols
    diagnostics = {
      [vim.diagnostic.severity.ERROR] = { enabled = false },
      [vim.diagnostic.severity.WARN] = { enabled = false },
      [vim.diagnostic.severity.INFO] = { enabled = false },
      [vim.diagnostic.severity.HINT] = { enabled = false },
    },
    gitsigns = {
      added = { enabled = false },
      changed = { enabled = false },
      deleted = { enabled = false },
    },
    filetype = {
      -- Sets the icon's highlight group.
      -- If false, will use nvim-web-devicons colors
      custom_colors = false,

      -- Requires `nvim-web-devicons` if `true`
      enabled = false,
    },
    separator = { left = "", right = "" },
    maximum_padding = 0,
    minimum_padding = 0,
    -- If true, add an additional separator at the end of the buffer list
    separator_at_end = false,

    -- Configure the icons on the bufferline when modified or pinned.
    -- Supports all the base icon options.
    modified = { button = "" },
    pinned = { button = "", filename = false },
    current = { button = "" },
    inactive = { button = "" },
  },
}
