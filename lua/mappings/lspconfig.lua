local map = require "mappings.map"
local telescope_builtin = require "telescope.builtin"
local lsp_signature = require "lsp_signature"
local function opts(desc)
  return { desc = "LSP " .. desc }
end

map("n", "<leader>lr", function()
  vim.cmd "Lspsaga finder"
end, opts "references (usages)")

map("n", "<leader>ltd", function()
  telescope_builtin.lsp_type_definitions { bufnr = 0 }
end, opts "type definitions")

map("n", "<leader>ld", function()
  telescope_builtin.lsp_definitions { bufnr = 0 }
end, opts "definitions")

map("n", "<leader>lci", function()
  vim.cmd "Lspsaga incoming_calls"
end, opts "show incoming calls")

map("n", "<leader>lco", function()
  vim.cmd "Lspsaga outgoing_calls"
end, opts "show outcoming calls")

map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, opts "renamer")

map("n", "<leader>pp", function()
  local path = vim.fn.input "Provide path to python executable of project: "
  vim.fn.system(path .. " -m pip install pydebug debugpy")
  vim.cmd("LspPyrightSetPythonPath " .. path)
  require("dap-python").setup(path)
  vim.print "Python venv setup completed"
end, opts "Set python path")

map("n", "<leader>pv", function()
  local path = ".venv/bin/python"
  vim.fn.system(path .. " -m pip install pydebug debugpy")
  vim.cmd("LspPyrightSetPythonPath " .. path)
  require("dap-python").setup(path)
  vim.print "Python venv setup completed"
end, opts "Set python to ./venv/bin/python")

map("n", "K", function()
  lsp_signature.check_signature_should_close()
  lsp_signature.toggle_float_win()
end, { silent = true, noremap = true, desc = "LSP toggle signature" })

map("i", "<C-k>", function()
  lsp_signature.toggle_float_win()
end, { desc = "LSP toggle signature" })

map("n", "H", vim.lsp.buf.hover, opts "Hover")
map("i", "<C-h>", vim.lsp.buf.hover, opts "Hover")
