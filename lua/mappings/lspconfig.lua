local map = require "mappings.map"
local trouble = require "trouble"
local close_trouble_succeeded = require "moonshine.utils.close_trouble_succeeded"
local ui_prevent_mess = require "moonshine.utils.ui_prevent_mess"

local telescope_builtin = require "telescope.builtin"
local check_multicursor_is_used = require "utils.check_multicursor_is_used"

local function map_lsp(mode, lhs, callback, options)
  map(mode, lhs, function()
    if check_multicursor_is_used() then
      return
    end
    callback()
  end, options)
end

local function opts(desc)
  return { desc = "LSP " .. desc }
end

map_lsp("n", "<leader>lr", function()
  close_trouble_succeeded()
  ui_prevent_mess()
  trouble.open {
    mode = "lsp_references",
    focus = true,
  }
end, opts "find references (usages)")

map_lsp("n", "<leader>lu", function()
  close_trouble_succeeded()
  ui_prevent_mess()
  trouble.open {
    mode = "lsp_references",
    focus = true,
  }
end, opts "find references (usages)")

map_lsp("n", "<leader>li", function()
  close_trouble_succeeded()
  ui_prevent_mess()
  trouble.open {
    mode = "lsp_implementations",
    focus = true,
  }
end, opts "implementations")

map_lsp("n", "<leader>ltd", function()
  require("lspeek").peek_type_definition()
end, opts "type definitions")

map_lsp("n", "<leader>ld", function()
  require("lspeek").peek_definition()
end, opts "definitions")

map_lsp("n", "<leader>lci", function()
  ui_prevent_mess()
  telescope_builtin.lsp_incoming_calls { bufnr = 0 }
end, opts "show incoming calls")

map_lsp("n", "<leader>lco", function()
  ui_prevent_mess()
  telescope_builtin.lsp_outgoing_calls { bufnr = 0 }
end, opts "show outcoming calls")

map_lsp("n", "<leader>lhu", function()
  vim.lsp.buf.typehierarchy("supertypes")
end, opts "type hierarchy superclasses")

map_lsp("n", "<leader>lhd", function()
  vim.lsp.buf.typehierarchy("subtypes")
end, opts "type hierarchy subclasses")

map_lsp("n", "<leader>rn", function()
  vim.lsp.buf.rename()
end, opts "renamer")

map_lsp("n", "K", function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "LSP toggle signature" })

map_lsp("i", "<C-k>", function()
  vim.lsp.buf.signature_help()
end, { silent = true, noremap = true, desc = "LSP toggle signature" })

local hover_params = { max_height = 25, max_width = 120 }

map_lsp("n", "H", function()
  vim.lsp.buf.hover(hover_params)
end, opts "Hover")
map_lsp("i", "<C-h>", function()
  vim.lsp.buf.hover(hover_params)
end, opts "Hover")
