-- Custom ft needs the markdown parser, otherwise render-markdown has nothing to query.
vim.treesitter.language.register("markdown", "todotxt-preview")

require("render-markdown").setup {
  -- Scrolling triggers both CursorMoved and WinScrolled; batch the viewport refreshes.
  debounce = 230,
  completions = { lsp = { enabled = true } },
  file_types = { "markdown", "codecompanion", "todotxt-preview" },
  code = {
    -- Turn on / off code block & inline code rendering.
    enabled = true,
    language_icon = false,
    border = "thin",
    language_left = "",
  },
  latex = {
    enabled = false,
  },
  heading = {
    enabled = true,
    render_modes = false,
    atx = true,
    setext = true,
    sign = true,
    icons = { " 󰉫 ", " 󰉬 ", " 󰉭 ", " 󰉮 ", " 󰉯 ", " 󰉰 " },
    backgrounds = {
      "RenderMarkdownH1Bg",
      "RenderMarkdownH2Bg",
      "RenderMarkdownH3Bg",
      "RenderMarkdownH4Bg",
      "RenderMarkdownH5Bg",
      "RenderMarkdownH6Bg",
    },
    foregrounds = {
      "RenderMarkdownH1",
      "RenderMarkdownH2",
      "RenderMarkdownH3",
      "RenderMarkdownH4",
      "RenderMarkdownH5",
      "RenderMarkdownH6",
    },
  },
  overrides = {
    filetype = {
      ["todotxt-preview"] = {
        anti_conceal = { enabled = false },
        render_modes = true,
      },
    },
  },
}
