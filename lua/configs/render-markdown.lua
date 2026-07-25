-- Custom ft needs the markdown parser, otherwise render-markdown has nothing to query.
vim.treesitter.language.register("markdown", "todotxt-preview")

require("render-markdown").setup {
  completions = { lsp = { enabled = true } },
  file_types = { "markdown", "codecompanion", "todotxt-preview" },
  code = {
    -- Turn on / off code block & inline code rendering.
    enabled = true,
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
      "RenderMarkdownH2Bg",
      "RenderMarkdownH2Bg",
      "RenderMarkdownH2Bg",
      "RenderMarkdownH2Bg",
    },
    foregrounds = {
      "RenderMarkdownH1",
      "RenderMarkdownH2",
      "RenderMarkdownH2",
      "RenderMarkdownH2",
      "RenderMarkdownH2",
      "RenderMarkdownH2",
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
