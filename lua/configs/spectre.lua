require("spectre").setup {
  mapping = {
    ["run_replace"] = {
      map = "<leader>RR",
      cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
      desc = "replace all",
    },
  },
}
