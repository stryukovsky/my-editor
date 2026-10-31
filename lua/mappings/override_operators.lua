local map = require "mappings.map"

-- Keep copied text when deleting/changing; an empty clipboard can accept deletions.
for _, key in ipairs { "d", "D", "c", "C", "x", "X", "s", "S", "." } do
  map(key == "." and "n" or { "n", "x" }, key, function()
    local register = vim.v.register
    if register ~= '"' and register ~= "+" then
      return key
    end
    local ok, clipboard = pcall(vim.fn.getreg, "+")
    if not ok or clipboard ~= "" then
      return '"_' .. key
    end
    return key
  end, { expr = true, desc = "Delete/change without overwriting clipboard" })
end

-- Helper to set search register without moving cursor
local function highlight_current(is_visual)
  local pattern
  if is_visual then
    -- Get current visual selection
    local saved_reg = vim.fn.getreg '"'
    vim.cmd 'noautocmd normal! "vy'
    pattern = "\\V" .. vim.fn.escape(vim.fn.getreg '"', "\\/")
    vim.fn.setreg('"', saved_reg)
  else
    -- Get word under cursor with word boundaries
    pattern = "\\<" .. vim.fn.expand "<cword>" .. "\\>"
  end

  -- Set the search register and enable highlighting
  vim.fn.setreg("/", pattern)
  vim.opt.hlsearch = true
    require("configs.slashing").activate()
end

-- Map # to highlight word under cursor
map("n", "#", function()
  highlight_current(false)
end, { desc = "Highlight word under cursor" })

-- Map # to highlight current visual selection
map("v", "#", function()
  highlight_current(true)
end, { desc = "Highlight visual selection" })
