local map = require "mappings.map"

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CsvViewMappings", { clear = true }),
  pattern = "csv",
  callback = function(ev)
    map(
      "n",
      "<A-I>",
      "<cmd>CsvViewToggle<cr>",
      { buffer = ev.buf, desc = "CSV toggle view" }
    )
  end,
})
