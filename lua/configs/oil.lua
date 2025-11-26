require("oil").setup {
  columns = {
    "icon",
    "permissions",
    "size",
    -- "mtime",
  },
  view_options = {
    show_hidden = true,
  },
  float = {
    -- Padding around the floating window
    padding = 0,
    -- max_width and max_height can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
    max_width = 0.99,
    max_height = 0.99,
    border = "rounded",
  },
  preview_win = {
    disable_preview = function(_)
      return true
    end,
    -- Window-local options to use for preview window buffers
    win_options = {},
  },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    -- ["<A-s>"] = { "actions.select", opts = { vertical = true } },
    -- ["<A-h>"] = { "actions.select", opts = { horizontal = true } },
    -- ["<A-t>"] = { "actions.select", opts = { tab = true } },
    ["<A-p>"] = "actions.preview",
    ["<A-e>"] = function(_) end,
    ["<A-l>"] = function(_) end,
    ["<A-b>"] = function(_) end,
    -- ["<C-c>"] = { "actions.close", mode = "n" },
    -- ["<C-l>"] = "actions.refresh",
    ["-"] = { "actions.parent", mode = "n" },
    ["<bs>"] = { "actions.parent", mode = "n" },
    --  ["_"] = { "actions.open_cwd", mode = "n" },
    -- ["`"] = { "actions.cd", mode = "n" },
    -- ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    -- ["gs"] = { "actions.change_sort", mode = "n" },
    -- ["gx"] = "actions.open_external",
    ["H"] = { "actions.toggle_hidden", mode = "n" },
    -- ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
}
