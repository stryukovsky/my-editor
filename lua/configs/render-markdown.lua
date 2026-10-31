-- Custom ft needs the markdown parser, otherwise render-markdown has nothing to query.
vim.treesitter.language.register("markdown", "todotxt-preview")

local math = require "configs.markdown-math"

require("render-markdown").setup {
  enabled = false,
  -- Scrolling triggers both CursorMoved and WinScrolled; batch the viewport refreshes.
  debounce = 230,
  completions = { lsp = { enabled = true } },
  file_types = { "markdown", "todotxt-preview" },
  anti_conceal = { enabled = false },
  win_options = {
    -- Math commands use conceal; buffer-local queries keep Markdown markers visible.
    conceallevel = { default = 0, rendered = 2 },
    concealcursor = { rendered = "nvic" },
  },
  bullet = { enabled = true },
  heading = { enabled = true },
  paragraph = { enabled = false },
  code = {
    enabled = false,
    inline = false,
    inline_left = "`",
    inline_right = "`",
  },
  nested = { enabled = false },
  dash = { enabled = true },
  document = { enabled = false },
  checkbox = { enabled = true },
  quote = { enabled = false },
  pipe_table = { enabled = false },
  table = { enabled = false },
  link = { enabled = false },
  sign = { enabled = false },
  inline_highlight = { enabled = false },
  indent = { enabled = false },
  html = { enabled = false },
  latex = { enabled = true },
  custom_handlers = { latex = { parse = math.parse } },
  on = { render = math.render, clear = math.clear },
  yaml = { enabled = false },
  overrides = {
    filetype = {
      ["todotxt-preview"] = { render_modes = true },
    },
  },
}
