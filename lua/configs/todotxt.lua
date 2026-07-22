require("todotxt").setup {
  lsp = true,
  todotxt = vim.env.HOME .. "/Documents/todo.txt",
  donetxt = vim.env.HOME .. "/Documents/done.txt",
  max_priority = "C",
  metadata = {
    -- asc/desc strings
    tag = { sort = "asc" },
    due = { sort = "desc" },
    -- custom comparator: a comes before b if tonumber(a) < tonumber(b)
    effort = {
      sort = function(a, b)
        return tonumber(a) < tonumber(b)
      end,
    },
  },
  ghost_text = {
    enable = true,
    mappings = {
      ["(A)"] = "URGENT",
      ["(B)"] = "NORMAL",
      ["(C)"] = "FREE",
    },
  },
}
