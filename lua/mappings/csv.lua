local map = require "mappings.map"

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CsvRenderMappings", { clear = true }),
  pattern = { "csv", "tsv" },
  callback = function(ev)
    map("n", "<A-i>", function()
      require("moonshine.csv_render").toggle()
    end, { buffer = ev.buf, desc = "CSV table preview" })
  end,
})
