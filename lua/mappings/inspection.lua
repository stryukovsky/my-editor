local map = require "mappings.map"
local md_table_viewer = require "moonshine.markdown.table"
local csv_table_viewer = require "integrations.csv_table_viewer"
local navigation_repeat = require "utils.navigation_repeat"

map("n", "<A-i>", function()
  local ft = vim.bo.filetype
  if ft == "markdown" then
    local render = require "render-markdown"
    local preview = require "render-markdown.core.preview"
    local closing = preview.get(vim.api.nvim_get_current_buf()) ~= nil
    render.preview()
    if not closing then
      render.buf_enable()
    end
  elseif ft == "csv" or ft == "tsv" then
    csv_table_viewer.view_row()
  elseif ft == "lean" or ft == "leaninfo" then
    require("lean.infoview").toggle()
  else
    vim.diagnostic.open_float()
  end
end, { desc = "Markdown preview / CSV row / Lean infoview / diagnostic" })

map("n", "<leader>mdi", function()
  if vim.bo.filetype == "markdown" then
    md_table_viewer.view_row()
  end
end, { desc = "Inspect Markdown table row" })

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
  navigation_repeat.set(function()
    goto_diagnostic(1)
  end, function()
    goto_diagnostic(-1)
  end, "diagnostic")
  goto_diagnostic(direction)
end

map("n", "]d", function()
  navigate_diagnostic(1)
end, { desc = "Next diagnostic (center + float)" })

map("n", "[d", function()
  navigate_diagnostic(-1)
end, { desc = "Prev diagnostic (center + float)" })
