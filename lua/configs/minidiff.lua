local MiniDiff = require "mini.diff"

if vim.g.minidiff_overlay == nil then
  vim.g.minidiff_overlay = false
end

MiniDiff.setup {
  view = {
    style = "sign",
    signs = { add = "┃", change = "┃", delete = "┃" },
  },
  -- Default maps use vim.keymap.set; keep them off and bind via mappings.map.
  mappings = {
    apply = "",
    reset = "",
    textobject = "",
    goto_first = "",
    goto_prev = "",
    goto_next = "",
    goto_last = "",
  },
  options = {
    algorithm = "histogram",
    indent_heuristic = true,
    linematch = 0,
    wrap_goto = true,
  },
}

return require "moonshine.diff"
