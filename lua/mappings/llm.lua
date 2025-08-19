local map = require "mappings.map"

map({"x", "v", "n"}, "<leader>aa", "<cmd>CodeCompanionActions<cr>", {desc = "AI actions"})
--
-- local function explain()
--   vim.cmd "LLMSelectedTextHandler explain"
-- end
--
-- local function ask()
--   vim.cmd "LLMAppHandler Ask"
-- end
--
-- local function translate()
--   vim.cmd "LLMAppHandler WordTranslate"
-- end
--
-- local function test()
--   vim.cmd "LLMAppHandler TestCode"
-- end
--
-- local function docs()
--   vim.cmd "LLMAppHandler DocString"
-- end
--
-- map("v", "<leader>exp", explain, { desc = "LLM Explain" })
-- map("v", "<leader>ask", ask, { desc = "LLM Ask" })
-- map("v", "<leader>tra", translate, { desc = "LLM Translate" })
-- map("v", "<leader>test", test, { desc = "LLM Test" })
-- map("v", "<leader>doc", docs, { desc = "LLM Doc" })


