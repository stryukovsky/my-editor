local map = require "mappings.map"
local md_table_viewer = require "configs.md_table_viewer"
local csv_table_viewer = require "configs.csv_table_viewer"
local navigation_repeat = require "utils.navigation_repeat"

map("n", "<A-i>", function()
  local ft = vim.bo.filetype
  if ft == "markdown" then
    md_table_viewer.view_row()
  elseif ft == "csv" or ft == "tsv" then
    csv_table_viewer.view_row()
  else
    vim.diagnostic.open_float()
  end
end, { desc = "View markdown/CSV row or show diagnostic" })

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

local function navigate_diagnostic(direction)
  navigation_repeat.set(
    function()
      goto_diagnostic(1)
    end,
    function()
      goto_diagnostic(-1)
    end,
    "diagnostic"
  )
  goto_diagnostic(direction)
end

map("n", "]d", function()
  navigate_diagnostic(1)
end, { desc = "Next diagnostic (center + float)" })

map("n", "[d", function()
  navigate_diagnostic(-1)
end, { desc = "Prev diagnostic (center + float)" })
