require("render-markdown").setup {
  completions = { lsp = { enabled = true } },
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
}
