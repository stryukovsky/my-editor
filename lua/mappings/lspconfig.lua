local map = vim.keymap.set
local telescope_builtin = require "telescope.builtin"
local nvrenamer = require "configs.nvrenamer"

return function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
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

  map("n", "<A-p>", function()
    telescope_builtin.diagnostics { bufnr = 0 }
  end, opts "inspections on current buffer")

  map("n", "<leader>ra", nvrenamer, opts "renamer")

  map("n", "<A-P>", function()
    telescope_builtin.diagnostics {}
  end, opts "inspections on all")

  map("n", "<leader>pp", function()
    vim.cmd("PyrightSetPythonPath " .. vim.fn.input("Provide path to python executable of project: "))
  end, opts "Set python path")

  map("n", "<leader>pv", function()
    vim.cmd("PyrightSetPythonPath venv/bin/python")
  end, opts "Set python to ./venv/bin/python")

  map("n", "K", vim.lsp.buf.signature_help, opts "Show signature help")
  map("n", "H", vim.lsp.buf.hover, opts "Hover")
end
