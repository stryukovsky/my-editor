local map = require "mappings.map"
local trouble = require "trouble"
local close_trouble = require "utils/close_trouble"

local telescope_builtin = require "telescope.builtin"
local function opts(desc)
  return { desc = "LSP " .. desc }
end

map("n", "<leader>lr", function()
  close_trouble()
  trouble.open {
    mode = "lsp_references",
    focus = true,
  }
end, opts "find references (usages)")

map("n", "<leader>lu", function()
  close_trouble()
  trouble.open {
    mode = "lsp_references",
    focus = true,
  }
end, opts "find references (usages)")

map("n", "<leader>li", function()
  telescope_builtin.lsp_implementations { bufnr = 0 }
end, opts "implementations")

map("n", "<leader>ltd", function()
  require("lspeek").peek_type_definition()
end, opts "type definitions")

map("n", "<leader>ld", function()
  require("lspeek").peek_definition()
end, opts "definitions")

map("n", "<leader>lci", function()
  telescope_builtin.lsp_incoming_calls { bufnr = 0 }
end, opts "show incoming calls")

map("n", "<leader>lco", function()
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

map("n", "<leader>scala", function()
  require("configs.scalametals").enable()
end, opts "Scala: enable Metals")

local function metals_opts(desc)
  return { desc = "Metals: " .. desc }
end

map("n", "<leader>me", function()
  require("configs.scalametals").telescope_commands()
end, metals_opts "commands")

map("n", "<leader>mec", function()
  require("configs.scalametals").telescope_commands()
end, metals_opts "commands (Telescope)")

map("n", "<leader>mel", function()
  require("configs.scalametals").show_logs()
end, metals_opts "open logs")

map("n", "<leader>med", function()
  require("configs.scalametals").run_doctor()
end, metals_opts "open doctor")

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
