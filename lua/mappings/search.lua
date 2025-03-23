local map = require "mappings.map"
local telescope = require "telescope"

-- search and replace
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope search contents (grep)" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

map("n", "<leader>rr", function()
  local toReplace = tostring(vim.fn.input "Input string to replace: ")
  if toReplace == "" then
    print ""
    return
  end
  local replaceWith = tostring(vim.fn.input "Input new string: ")
  if replaceWith == "" then
    print ""
    return
  end
  vim.api.nvim_feedkeys(":%s/" .. toReplace .. "/" .. replaceWith)
end, { desc = "replace in file" })

map("n", "<leader>ri", function()
  local toReplace = tostring(vim.fn.input "[Interval] Input string to replace: ")
  if toReplace == "" then
    print ""
    return
  end
  local replaceWith = tostring(vim.fn.input "[Interval] Input new string: ")
  if replaceWith == "" then
    print ""
    return
  end
  local intervalStr = tostring(vim.fn.input "[Interval] Input two numbers of lines interval: ")
  local numbers = {}
  local numbersCount = 0
  for number in string.gmatch(intervalStr, "%d+") do
    numbers[#numbers + 1] = tonumber(number)
    numbersCount = numbersCount + 1
  end
  if numbersCount == 2 then
    vim.api.nvim_feedkeys(tostring(numbers[1]) .. "," .. tostring(numbers[2]) .. "s/" .. toReplace .. "/" .. replaceWith .. "/g")
  elseif numbersCount == 1 then
    local firstNumber = numbers[1]
    local secondNumberStr =
      vim.fn.input("[Interval] Input second number or replace only on " .. firstNumber .. " line: ")
    local secondNumber = firstNumber
    if secondNumberStr ~= "" then
      secondNumber = tonumber(secondNumberStr)
      if secondNumber == nil then
        print "[Interval] Bad number provided"
        return
      end
    end
    vim.api.nvim_feedkeys(tostring(numbers[1]) .. "," .. tostring(secondNumber) .. "s/" .. toReplace .. "/" .. replaceWith .. "/g")
  else
    print "[Interval] Expected two numbers or one number"
  end
end, { desc = "replace in interval" })

-- telescope extensions
-- undo
map("n", "<leader>u", function()
  telescope.extensions.undo.undo()
end)

require("telescope").setup {
  extensions = {
    undo = {
      mappings = {
        i = {
          ["<A-y>"] = require("telescope-undo.actions").yank_additions,
          ["<A-Y>"] = require("telescope-undo.actions").yank_deletions,
          ["<A-r>"] = require("telescope-undo.actions").restore,
        },
        n = {
          ["y"] = require("telescope-undo.actions").yank_additions,
          ["Y"] = require("telescope-undo.actions").yank_deletions,
          ["u"] = require("telescope-undo.actions").restore,
        },
      },
    },
  },
}
