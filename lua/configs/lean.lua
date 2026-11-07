-- lean.nvim owns Lean's LSP configuration and reads this when it loads.
vim.g.lean_config = {
  mappings = false, -- Defined through langmapper in mappings.lean.
  abbreviations = { enable = true },
  infoview = { autoopen = false },
}
