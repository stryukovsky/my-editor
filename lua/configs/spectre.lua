require("spectre").setup {
  find_engine = {
    -- rg is map with finder_cmd
    ["rg"] = {
      cmd = vim.fn.stdpath "config" .. "/rg",
      -- default args
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
      },
      options = {
        ["ignore-case"] = {
          value = "--ignore-case",
          icon = "[I]",
          desc = "ignore case",
        },
        ["hidden"] = {
          value = "--hidden",
          desc = "hidden file",
          icon = "[H]",
        },
        -- you can put any rg search option you want here it can toggle with
        -- show_option function
      },
    },
  },
  mapping = {
    ["run_replace"] = {
      map = "<leader>RR",
      cmd = "<cmd>lua require('spectre.actions').run_replace()<CR>",
      desc = "replace all",
    },
  },
}
