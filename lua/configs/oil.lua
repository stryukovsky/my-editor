require("oil").setup {
  columns = {
    "icon",
    "permissions",
    "size",
    -- "mtime",
  },
  view_options = {
    show_hidden = false,
  },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    -- ["<A-s>"] = { "actions.select", opts = { vertical = true } },
    -- ["<A-h>"] = { "actions.select", opts = { horizontal = true } },
    -- ["<A-t>"] = { "actions.select", opts = { tab = true } },
    ["<A-p>"] = "actions.preview",
    -- ["<C-c>"] = { "actions.close", mode = "n" },
    -- ["<C-l>"] = "actions.refresh",
    --  ["-"] = { "actions.parent", mode = "n" },
    --  ["_"] = { "actions.open_cwd", mode = "n" },
    -- ["`"] = { "actions.cd", mode = "n" },
    -- ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    -- ["gs"] = { "actions.change_sort", mode = "n" },
    -- ["gx"] = "actions.open_external",
    ["H"] = { "actions.toggle_hidden", mode = "n" },
    -- ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
}
