local M = {}

function M.actions(bufnr)
  return {
    {
      id = "start",
      name = "Start rust-analyzer",
      desc = "rust",
      run = function()
        vim.b[bufnr].lsp_disabled = false
        vim.api.nvim_buf_call(bufnr, function()
          vim.cmd "RustAnalyzer start"
        end)
      end,
    },
  }
end

return M
