local map = require "mappings.map"
map({ "s", "n" }, "<Tab>", function()
  if vim.snippet.active { direction = 1 } then
    vim.snippet.jump(1)
  end
end, { expr = true, silent = true })

map({ "s", "n" }, "<S-Tab>", function()
  if vim.snippet.active { direction = -1 } then
    vim.snippet.jump(-1)
  end
end, { expr = true, silent = true })
