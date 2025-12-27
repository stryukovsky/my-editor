require("spectre").setup {
  mapping = {
    ["run_replace"] = {
      map = "<leader>RR",
      cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
      desc = "replace all",
    },
    ["enter_file"] = {
      map = "<cr>",
      cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
      desc = "open file",
    },
    ["open_file"] = {
      map = "o",
      cmd = "<cmd>lua require('spectre.actions').select_entry()<CR>",
      desc = "open file",
    },
  },
}
