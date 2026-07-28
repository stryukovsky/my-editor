local map = require "mappings.map"
local async = require "plenary.async"

map("n", "<leader>md", "<cmd>MarkdownPreviewToggle<CR>", { desc = "MarkdownPreview toggle" })

map("n", "<leader>pdf", function()
  local source = vim.api.nvim_buf_get_name(0)
  if source == "" then
    vim.notify("Save the Markdown file before exporting it to PDF", vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable "pandoc" == 0 then
    vim.notify("pandoc is not installed", vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable "xelatex" == 0 then
    vim.notify("xelatex is not installed", vim.log.levels.ERROR)
    return
  end

  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, "write")
    if not ok then
      vim.notify("Could not save Markdown file: " .. err, vim.log.levels.ERROR)
      return
    end
  end

  local output = vim.fn.fnamemodify(source, ":r") .. ".pdf"
  vim.notify("Generating PDF: " .. output)

  async.run(function()
    local result = async.wrap(vim.system, 3)(
      { "pandoc", vim.fn.fnamemodify(source, ":t"), "--pdf-engine=xelatex", "-o", output },
      { cwd = vim.fn.fnamemodify(source, ":h"), text = true }
    )

    vim.schedule(function()
      if result.code == 0 then
        vim.notify("Created PDF: " .. output)
      else
        vim.notify("PDF generation failed: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
      end
    end)
  end, function() end)
end, { desc = "Markdown export PDF" })
