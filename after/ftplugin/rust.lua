local bufnr = vim.api.nvim_get_current_buf()

-- vim.keymap.set("n", "<leader>ca", function()
--   vim.cmd.RustLsp "codeAction" -- supports rust-analyzer's grouping
-- end, { silent = true, buffer = bufnr })
vim.keymap.set(
  "n",
  "H", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
  function()
    vim.cmd.RustLsp { "hover", "actions" }
  end,
  { silent = true, buffer = bufnr }
)

vim.keymap.set(
  "n",
  "<leader>dd", -- Override Neovim's built-in hover keymap with rustaceanvim's hover actions
  function()
    vim.cmd.RustLsp "debuggables"
  end,
  { silent = true, buffer = bufnr }
)
