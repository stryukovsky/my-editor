local map = require "mappings.map"
local scenarios = require "scenarios_of_codebase"

map("n", "<leader>scc", scenarios.create, { desc = "Scenarios: create" })
map("n", "<leader>scn", scenarios.next, { desc = "Scenarios: next location" })
map("n", "<leader>sca", scenarios.append, { desc = "Scenarios: append point" })
map("n", "<leader>scv", scenarios.view, { desc = "Scenarios: view for current project" })
map("n", "<leader>scp", scenarios.previous, { desc = "Scenarios: previous location" })
map("n", "<leader>scr", scenarios.replay, { desc = "Scenarios: replay from start" })
map("n", "<leader>scq", scenarios.quit, { desc = "Scenarios: quit" })
map("n", "<leader>scyp", scenarios.yank_prompt, { desc = "Scenarios: yank AI prompt" })
