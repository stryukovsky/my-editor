local harpoon = require "harpoon"

local function add_sign_to_current_line()
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1] -- Get current line (1-based)

  -- Place the sign
  -- The 'id' must be unique; here we use the line number for simplicity
  vim.fn.sign_place(
    line, -- Unique ID for the sign
    "harpoon", -- The sign defined earlier
    "HarpoonLine", -- Group name (can be anything)
    bufnr, -- Current buffer
    { lnum = line } -- Line number to place the sign
  )
end

vim.keymap.set("n", "<leader>1", function()
  harpoon:list():add()
  add_sign_to_current_line()
end)

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

vim.keymap.set("n", "<leader><leader>", function()
  toggle_telescope(harpoon:list())
end, { desc = "Open harpoon window" })

vim.keymap.set("n", "<A-1>", function()
  harpoon:list():select(1)
end)
vim.keymap.set("n", "<A-2>", function()
  harpoon:list():select(2)
end)
vim.keymap.set("n", "<A-3>", function()
  harpoon:list():select(3)
end)
vim.keymap.set("n", "<A-4>", function()
  harpoon:list():select(4)
end)
vim.keymap.set("n", "<A-5>", function()
  harpoon:list():select(5)
end)
vim.keymap.set("n", "<leader>cc", function()
  harpoon:list():clear()
end)

-- Toggle previous & next buffers stored within Harpoon list
vim.keymap.set("n", "<A-{>", function()
  harpoon:list():prev()
end)
vim.keymap.set("n", "<A-}>", function()
  harpoon:list():next()
end)
