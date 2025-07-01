local map = require "mappings.map"

local function explain()
  vim.cmd "LLMSelectedTextHandler explain"
end

local function ask()
  vim.cmd "LLMSelectedTextHandler ask"
end

map("v", "<leader>exp", explain, { desc = "LLM Explain" })
map("v", "<leader>ask", ask, { desc = "LLM Ask" })
