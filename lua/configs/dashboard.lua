require("dashboard").setup {
  theme = "hyper",
  config = {
    week_header = {
      enable = true,
    },
    project = { enable = false },
    mru = { enable = false },
    shortcut = {
      {
        desc = "Update",
        group = "Label",
        action = "Lazy update",
        key = "u",
      },
      {
        desc = "Files",
        group = "Label",
        action = "Telescope find_files",
        key = "f",
      },
    },
  },
}
