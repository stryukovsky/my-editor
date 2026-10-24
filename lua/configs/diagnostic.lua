vim.diagnostic.config { virtual_lines = false }

-- Neovim's pull-diagnostic handler indexes cancellation data without checking JSON null.
local diagnostic_handler = vim.lsp.handlers["textDocument/diagnostic"]
vim.lsp.handlers["textDocument/diagnostic"] = function(err, result, ctx, config)
  if err and err.code == vim.lsp.protocol.ErrorCodes.ServerCancelled and err.data == vim.NIL then
    err = vim.tbl_extend("force", {}, err)
    err.data = nil
  end
  return diagnostic_handler(err, result, ctx, config)
end
