-- Custom ft needs the markdown parser, otherwise render-markdown has nothing to query.
vim.treesitter.language.register("markdown", "todotxt-preview")

require("render-markdown").setup {
  enabled = true,
  -- Scrolling triggers both CursorMoved and WinScrolled; batch the viewport refreshes.
  debounce = 230,
  completions = { lsp = { enabled = true } },
  file_types = { "markdown", "todotxt-preview" },
  anti_conceal = { enabled = false },
  win_options = {
    concealcursor = { rendered = "nvic" },
  },
  bullet = { enabled = true },
  heading = { enabled = true },
  paragraph = { enabled = false },
  code = { enabled = false },
  dash = { enabled = false },
  document = { enabled = false },
  checkbox = { enabled = true },
  quote = { enabled = false },
  pipe_table = { enabled = false },
  link = { enabled = false },
  sign = { enabled = false },
  inline_highlight = { enabled = false },
  indent = { enabled = false },
  html = { enabled = false },
  latex = { enabled = true },
  yaml = { enabled = false },
  overrides = {
    filetype = {
      ["todotxt-preview"] = { render_modes = true },
    },
  },
}
