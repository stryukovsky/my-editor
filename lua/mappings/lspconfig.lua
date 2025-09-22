local map = require "mappings.map"
local telescope_builtin = require "telescope.builtin"
local function opts(desc)
  return { desc = "LSP " .. desc }
end

map("n", "<leader>lr", function()
  telescope_builtin.lsp_references { bufnr = 0 }
end, opts "references (usages)")

map("n", "<leader>li", function()
  telescope_builtin.lsp_implementations { bufnr = 0 }
end, opts "implementations")

map("n", "<leader>ltd", function()
  telescope_builtin.lsp_type_definitions { bufnr = 0 }
end, opts "type definitions")

map("n", "<leader>ld", function()
  telescope_builtin.lsp_definitions { bufnr = 0 }
end, opts "definitions")

map("n", "<leader>lci", function()
  telescope_builtin.lsp_incoming_calls { bufnr = 0 }
end, opts "show incoming calls")

map("n", "<leader>lco", function()
  telescope_builtin.lsp_outgoing_calls { bufnr = 0 }
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
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "LSP toggle signature" })

map("i", "<C-k>", function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "LSP toggle signature" })

local hover_params = { max_height = 25, max_width = 120 }

map("n", "H", function()
  vim.lsp.buf.hover(hover_params)
end, opts "Hover")
map("i", "<C-h>", function()
  vim.lsp.buf.hover(hover_params)
end, opts "Hover")
