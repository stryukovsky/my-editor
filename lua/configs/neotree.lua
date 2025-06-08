require("neo-tree").setup {
  sources = { "document_symbols", "filesystem", "git_status" },
  source_selector = {
    winbar = true,
    statusline = false,
  },
}
