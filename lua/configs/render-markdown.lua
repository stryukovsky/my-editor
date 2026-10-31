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
    -- Buffer-local queries keep Markdown markers visible while rendering.
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

-- Materialize Unicode math before the preview measures/wraps prose and tables.
require("render-markdown.core.preview").transform = math.lines

-- The preview converter lives in the plugin; reuse our installed executable.
local bundled_mermaid = vim.fn.stdpath "config" .. "/bin/mermaid-ascii"
require("render-markdown.core.preview").mermaid = {
  command = vim.fn.executable(bundled_mermaid) == 1 and bundled_mermaid
    or "mermaid-ascii",
  timeout = 5000,
}
