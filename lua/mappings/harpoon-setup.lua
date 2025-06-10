local harpoon = require "harpoon"

vim.keymap.set("n", "<leader>h", function()
  harpoon:list():add()
  vim.print "Harpooned!"
end, { desc = "Harpoon add"})

-- basic telescope configuration
local conf = require("telescope.config").values
local function toggle_telescope(harpoon_files)
  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require("telescope.pickers")
    .new({}, {
      prompt_title = "Harpoon",
      finder = require("telescope.finders").new_table {
        results = file_paths,
      },
      previewer = conf.file_previewer {},
      sorter = conf.generic_sorter {},
    })
    :find()
end

vim.keymap.set("n", "<leader>ha", function()
  toggle_telescope(harpoon:list())
end, { desc = "Actions: harpoon" })
