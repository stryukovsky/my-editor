local hl = vim.api.nvim_set_hl

local M = {}

function M.apply_spellbad()
  if vim.g.grammar_strict then
    local red = require("material.colors").main.red
    hl(0, "SpellBad", { fg = red, italic = true, undercurl = true })
  else
    hl(0, "SpellBad", { undercurl = true })
  end
  hl(0, "SpellRare", {})
  hl(0, "SpellCap", {})
  hl(0, "SpellLocal", {})
end

return M
