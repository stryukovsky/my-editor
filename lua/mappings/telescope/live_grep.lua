local open_with_trouble = require("trouble.sources.telescope").open
return {
  n = {
    ["<cr>"] = function(bufnr, opts)
      open_with_trouble(bufnr, opts)
    end,
  },
  i = {
    ["<cr>"] = function(bufnr, opts)
      open_with_trouble(bufnr, opts)
    end,
  },
}
