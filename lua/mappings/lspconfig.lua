local map = require "mappings.map"
local trouble = require "trouble"
local close_trouble_succeeded = require "utils.close_trouble_succeeded"
local ui_prevent_mess = require "utils.ui_prevent_mess"

local telescope_builtin = require "telescope.builtin"
local function opts(desc)
  return { desc = "LSP " .. desc }
end

map("n", "<leader>lr", function()
  close_trouble_succeeded()
  ui_prevent_mess()
  trouble.open {
    mode = "lsp_references",
    focus = true,
  }
end, opts "find references (usages)")

map("n", "<leader>lu", function()
  close_trouble_succeeded()
  ui_prevent_mess()
  trouble.open {
    mode = "lsp_references",
    focus = true,
  }
end, opts "find references (usages)")

map("n", "<leader>li", function()
  close_trouble_succeeded()
  ui_prevent_mess()
  trouble.open {
    mode = "lsp_implementations",
    focus = true,
  }
end, opts "implementations")

map("n", "<leader>ltd", function()
  require("lspeek").peek_type_definition()
end, opts "type definitions")

map("n", "<leader>ld", function()
  require("lspeek").peek_definition()
end, opts "definitions")

map("n", "<leader>lci", function()
  ui_prevent_mess()
  telescope_builtin.lsp_incoming_calls { bufnr = 0 }
end, opts "show incoming calls")

map("n", "<leader>lco", function()
  ui_prevent_mess()
  telescope_builtin.lsp_outgoing_calls { bufnr = 0 }
end, opts "show outcoming calls")

map("n", "<leader>lhu", function()
  vim.lsp.buf.typehierarchy("supertypes")
end, opts "type hierarchy superclasses")

map("n", "<leader>lhd", function()
  vim.lsp.buf.typehierarchy("subtypes")
end, opts "type hierarchy subclasses")

map("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, opts "renamer")

map("n", "<leader>py", function()
  require("configs.python").setup()
end, opts "Python: setup")

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
