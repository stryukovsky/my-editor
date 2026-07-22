local map = require "mappings.map"
local todotxt = require "todotxt"

map("n", "<leader>jv", function()
  vim.cmd("edit" .. todotxt.config.todotxt)
end, { desc = "Work: open file with todos" })

map("n", "<leader>jj", function()
  todotxt.capture()
end, { desc = "Work: new task" })

map("n", "<leader>jss", function()
  todotxt.sort_tasks()
end, { desc = "Work: sort file" })

map("n", "<leader>js+", function()
  todotxt.sort_tasks_by_project()
end, { desc = "Work: sort on +Projects" })

map("n", "<leader>js@", function()
  todotxt.sort_tasks_by_priority()
end, { desc = "Work: sort on @Contexts" })

map("n", "<leader>jsd", function()
  todotxt.sort_tasks_by_due_date()
end, { desc = "Work: sort on dates" })

map("n", "<leader>jc", function()
  todotxt.cycle_priority()
end, { desc = "Work: cycle priority" })

map("n", "<leader>jtd", function() end, { desc = "Work: today date" })

map("n", "<leader>jtm", function() end, { desc = "Work: tomorrow date" })

map("n", "<leader>jx", function()
  todotxt.toggle_todo_state()
end, { desc = "Work: toggle todo state" })
map("n", "<leader>jX", function()
  todotxt.move_done_tasks()
end, { desc = "Work: move to done.txt" })
