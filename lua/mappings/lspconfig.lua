local map = vim.keymap.set
local telescope_builtin = require "telescope.builtin"
local nvrenamer = require "configs.nvrenamer"

return function(_, bufnr)
  local function opts(desc)
    return { buffer = bufnr, desc = "LSP " .. desc }
  end

  map("n", "<leader>lr", function()
    telescope_builtin.lsp_references {}
  end, opts "references (usages)")

  map("n", "<leader>ltd", function()
    telescope_builtin.lsp_type_definitions {}
  end, opts "type definitions")

  map("n", "<leader>li", function()
    telescope_builtin.lsp_implementations {}
  end, opts "implementations")

  map("n", "<leader>ld", function()
    telescope_builtin.lsp_definitions {}
  end, opts "definitions")

  map("n", "<leader>lci", function()
    telescope_builtin.lsp_incoming_calls {}
  end, opts "show incoming calls")

  map("n", "<leader>lco", function()
    telescope_builtin.lsp_outgoing_calls {}
  end, opts "show outcoming calls")

  map("n", "<A-p>", function()
    telescope_builtin.diagnostics { bufnr = 0 }
  end, opts "inspections on current buffer")

  map("n", "<leader>ra", nvrenamer, opts "renamer")

  map("n", "<A-P>", function()
    telescope_builtin.diagnostics {}
  end, opts "inspections on all")
end
