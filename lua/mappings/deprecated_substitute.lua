local map = require "mappings.map"
local spectre = require "spectre"

local is_normal_buffer = require "utils.is_normal_buffer"

-- Get filepath only if it's a normal editable buffer (relative to cwd)
local function get_editable_filepath()
  if is_normal_buffer() then
    local filepath = vim.api.nvim_buf_get_name(0)
    -- Get relative path from current working directory
    local relative_path = vim.fn.fnamemodify(filepath, ":.")
    -- Alternative: use string manipulation if you prefer
    -- local relative_path = filepath:gsub('^' .. vim.pesc(cwd .. '/'), '')
    return relative_path
  end
  return nil
end

map("x", "<leader>ri", function()
  vim.api.nvim_feedkeys(":s///g", "ni", false)
end, { noremap = true, desc = "Replace in selection" })

map("n", "<leader>rr", function()
  if vim.g.spectre_opened then
    spectre.close()
  end
  vim.g.spectre_opened = true
  local filepath = get_editable_filepath()
  if filepath then
    spectre.open { path = filepath }
  else
    vim.print "Not a normal file buffer"
  end
end, { noremap = true, desc = "Replace in all file" })
