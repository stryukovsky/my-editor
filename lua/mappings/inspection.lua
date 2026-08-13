local map = require "mappings.map"
local md_table_viewer = require "configs.md_table_viewer"

map("n", "<A-i>", function()
  if vim.bo.filetype == "markdown" then
    md_table_viewer.view_row()
  else
    vim.diagnostic.open_float()
  end
end, { desc = "Markdown: view table row / show diagnostic" })

---@param direction 1|-1
local function goto_diagnostic(direction)
  local diag = vim.diagnostic.jump {
    count = direction * vim.v.count1,
    float = false,
  }
  if not diag then
    return
  end
  vim.cmd "normal! zz"
  -- open_float must run after CursorMoved from the jump, or the float is closed immediately.
  vim.schedule(function()
    vim.diagnostic.open_float { scope = "cursor", focus = false }
  end)
end

map("n", "]d", function()
  goto_diagnostic(1)
end, { desc = "Next diagnostic (center + float)" })

map("n", "[d", function()
  goto_diagnostic(-1)
end, { desc = "Prev diagnostic (center + float)" })
