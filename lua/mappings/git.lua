local map = require "mappings.map"
local git = require "configs.git_commands"

local bindings = {
  { "<leader>gp", git.pull, "pull with rebase and autostash" },
  { "<leader>gP", git.push, "push" },
  { "<leader>gf", git.fetch, "fetch" },
  { "<leader>gmc", git.merge_continue, "merge continue" },
  { "<leader>gma", git.merge_abort, "merge abort" },
  { "<leader>gta", git.stash, "stash changes" },
  { "<leader>gtp", git.stash_pop, "stash pop" },
  { "<leader>gbc", git.branch_create, "create and switch branch" },
  { "<leader>gbr", git.branch_rename, "rename current branch" },
  { "<leader>gc", git.commit, "commit staged changes" },
  { "<leader>gC", git.checkpoint, "commit checkpoint" },
}
for _, binding in ipairs(bindings) do
  map("n", binding[1], binding[2], { desc = "git: " .. binding[3] })
end


map(
  "n",
  "<leader>gx",
  "<cmd>GitConflictListQf<cr>",
  { desc = "git: conflicts" }
)
