local map = require "mappings.map"

local function explain()
  vim.cmd "LLMSelectedTextHandler explain"
end

local function ask()
  vim.cmd "LLMAppHandler Ask"
end

local function translate()
  vim.cmd "LLMAppHandler WordTranslate"
end

map("v", "<leader>exp", explain, { desc = "LLM Explain" })
map("v", "<leader>ask", ask, { desc = "LLM Ask" })
map("v", "<leader>tra", translate, { desc = "LLM Translate" })
