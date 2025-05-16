local map = vim.keymap.set
local telescope_builtin = require "telescope.builtin"
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
  vim.print("Python venv setup completed")
end, opts "Set python path")

map("n", "<leader>pv", function()
  local path = ".venv/bin/python"
  vim.fn.system(path .. " -m pip install pydebug debugpy")
  vim.cmd("LspPyrightSetPythonPath " .. path)
  require("dap-python").setup(path)
  vim.print("Python venv setup completed")
end, opts "Set python to ./venv/bin/python")

map("n", "K", vim.lsp.buf.signature_help, opts "Show signature help")
map("n", "H", vim.lsp.buf.hover, opts "Hover")
