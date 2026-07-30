local map = require "mappings.map"
local async = require "plenary.async"
local notify = require "configs.notify"

map("n", "<leader>md", "<cmd>MarkdownPreviewToggle<CR>", { desc = "MarkdownPreview toggle" })

map("n", "<leader>pdf", function()
  local source = vim.api.nvim_buf_get_name(0)
  if source == "" then
    notify.send("Markdown PDF", "Save the Markdown file before exporting it", vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable "pandoc" == 0 then
    notify.send("Markdown PDF", "pandoc is not installed", vim.log.levels.ERROR)
    return
  end
  if vim.fn.executable "xelatex" == 0 then
    notify.send("Markdown PDF", "xelatex is not installed", vim.log.levels.ERROR)
    return
  end

  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, "write")
    if not ok then
      notify.send("Markdown PDF", "Could not save Markdown file: " .. err, vim.log.levels.ERROR)
      return
    end
  end

  local output = vim.fn.fnamemodify(source, ":r") .. ".pdf"
  local config = vim.fn.stdpath "config"
  local table_filter = config .. "/pandoc/table-grid.lua"
  local table_header = config .. "/pandoc/table-grid-header.tex"
  notify.send("Markdown PDF", "Generating: " .. output)

  -- xelatex default fonts lack Cyrillic; pick system fonts that include Russian.
  -- Lua filter redraws tables as tabularx grid so cells wrap within page width.
  async.run(function()
    local result = async.wrap(vim.system, 3)({
      "pandoc",
      vim.fn.fnamemodify(source, ":t"),
      "--pdf-engine=xelatex",
      "--lua-filter=" .. table_filter,
      "-H",
      table_header,
      "-V",
      "mainfont=Liberation Sans",
      "-V",
      "monofont=Noto Sans Mono",
      "-V",
      "geometry:margin=1in",
      "-o",
      output,
    }, { cwd = vim.fn.fnamemodify(source, ":h"), text = true })

    vim.schedule(function()
      if result.code == 0 then
        notify.send("Markdown PDF", "Created: " .. output)
      else
        notify.send("Markdown PDF", "Generation failed: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
      end
    end)
  end, function() end)
end, { desc = "Markdown export PDF" })
