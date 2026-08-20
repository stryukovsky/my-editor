local map = require "mappings.map"
local todotxt = require "todotxt"
local notify = require "configs.notify"
local gitutils = require "configs.gitutils"
local open_scratch = require "utils.open_scratch"

local function git_failure_message(command, stderr)
  if not stderr or stderr == "" then
    return command .. " failed"
  end
  return command .. " failed:\n" .. stderr
end

---@return { file: string, root: string, rel: string }|nil
local function todotxt_repo()
  local todotxt_file = todotxt.config.todotxt
  if not todotxt_file then
    notify.send("Todo.txt", "Path not configured", vim.log.levels.WARN)
    return nil
  end
  local parent = vim.fn.fnamemodify(todotxt_file, ":h")
  local root = gitutils.root(parent)
  if not root then
    notify.send("Todo.txt", "Not a git repository: " .. parent, vim.log.levels.WARN)
    return nil
  end
  return {
    file = todotxt_file,
    root = root,
    rel = gitutils.relpath(todotxt_file, parent),
  }
end

map("n", "<leader>jv", function()
  vim.cmd("edit" .. todotxt.config.todotxt)
end, { desc = "Work: open file with todos" })

map("n", "<leader>js+", function()
  todotxt.sort_tasks_by_project()
end, { desc = "Work: sort on +Projects" })

local function priority_sorter(a, b)
  if a.priority and b.priority then
    return a.priority < b.priority
  end
  if a.priority and not b.priority then
    return true
  end
  if not a.priority and b.priority then
    return false
  end
  return false
end

local function group_tasks_by_project(lines)
  local by_project = {}
  local default_group = {}

  for _, line in ipairs(lines) do
    if line ~= "" and not line:match "^%s*x " then
      local priority = line:match "^%(([A-Z])%)"
      local first_proj = line:match "%+([^%s]+)"
      local entry = { line = line, priority = priority }
      if first_proj then
        if not by_project[first_proj] then
          by_project[first_proj] = {}
        end
        table.insert(by_project[first_proj], entry)
      else
        table.insert(default_group, entry)
      end
    end
  end

  local proj_names = vim.tbl_keys(by_project)
  table.sort(proj_names)

  for _, name in ipairs(proj_names) do
    table.sort(by_project[name], priority_sorter)
  end
  table.sort(default_group, priority_sorter)

  return by_project, proj_names, default_group
end

local function task_cell_text(line)
  local text = line:gsub("%+%S+", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""):gsub("|", "\\|")
  return text
end

map("n", "<leader>jss", function()
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  local by_project = {}
  local default_group = {}

  for _, line in ipairs(lines) do
    if line ~= "" then
      local priority = line:match "^%(([A-Z])%)"
      local first_proj = line:match "%+([^%s]+)"
      local entry = { line = line, priority = priority }
      if first_proj then
        if not by_project[first_proj] then
          by_project[first_proj] = {}
        end
        table.insert(by_project[first_proj], entry)
      else
        table.insert(default_group, entry)
      end
    end
  end

  local result = {}
  local proj_names = vim.tbl_keys(by_project)
  table.sort(proj_names)

  for i, name in ipairs(proj_names) do
    if i > 1 then
      table.insert(result, "")
      table.insert(result, "")
    end
    table.sort(by_project[name], priority_sorter)
    for _, task in ipairs(by_project[name]) do
      table.insert(result, task.line)
    end
  end

  if #default_group > 0 then
    if #proj_names > 0 then
      table.insert(result, "")
      table.insert(result, "")
    end
    table.sort(default_group, priority_sorter)
    for _, task in ipairs(default_group) do
      table.insert(result, task.line)
    end
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, result)
end, { desc = "Work: sort by project + priority" })

map("n", "<leader>jmd", function()
  local lines
  if vim.bo.filetype == "todotxt" then
    lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  else
    local todotxt_file = todotxt.config.todotxt
    if not todotxt_file or vim.fn.filereadable(todotxt_file) ~= 1 then
      notify.send("Todo.txt", "Path not configured or unreadable", vim.log.levels.WARN)
      return
    end
    lines = vim.fn.readfile(todotxt_file)
  end

  local by_project, proj_names, default_group = group_tasks_by_project(lines)

  if #default_group > 0 then
    table.insert(proj_names, "(none)")
    by_project["(none)"] = default_group
  end

  if #proj_names == 0 then
    notify.send("Todo.txt", "No tasks to preview")
    return
  end

  local columns = {}
  local max_rows = 0
  for _, name in ipairs(proj_names) do
    local cells = {}
    for _, task in ipairs(by_project[name]) do
      table.insert(cells, task_cell_text(task.line))
    end
    columns[name] = cells
    if #cells > max_rows then
      max_rows = #cells
    end
  end

  local header = "| " .. table.concat(proj_names, " | ") .. " |"
  local separator = "| " .. table.concat(
    vim.tbl_map(function()
      return "---"
    end, proj_names),
    " | "
  ) .. " |"

  local md = { header, separator }
  for row = 1, max_rows do
    local cells = {}
    for _, name in ipairs(proj_names) do
      table.insert(cells, columns[name][row] or "")
    end
    table.insert(md, "| " .. table.concat(cells, " | ") .. " |")
  end

  -- Name without .md so filetype detection does not overwrite todotxt-preview.
  open_scratch {
    name = "todotxt-preview",
    filetype = "todotxt-preview",
    lines = md,
    buftype = "",
  }
end, { desc = "Work: markdown table preview by project" })

map("n", "<leader>jc", function()
  todotxt.cycle_priority()
end, { desc = "Work: cycle priority" })

-- Same as <C-a> increment, but for (A)/(B)/(C) on the current task.
map("n", "<C-a>", function()
  if vim.bo.filetype == "todotxt" then
    todotxt.cycle_priority()
    return
  end
  vim.cmd("normal! " .. vim.v.count1 .. "\001")
end, { desc = "Increment / cycle todo priority" })

map("n", "<leader>jtd", function() end, { desc = "Work: today date" })

map("n", "<leader>jtm", function() end, { desc = "Work: tomorrow date" })

map("n", "<leader>jx", function()
  todotxt.toggle_todo_state()
end, { desc = "Work: toggle todo state" })
map("n", "<leader>jP", function()
  local repo = todotxt_repo()
  if not repo then
    return
  end
  gitutils.job {
    args = { "add", repo.rel },
    cwd = repo.root,
    on_exit = function(add_code, add_stderr)
      if add_code ~= 0 then
        notify.send("Todo.txt", git_failure_message("git add", add_stderr), vim.log.levels.ERROR)
        return
      end
      gitutils.job {
        args = { "commit", "-m", "update todotxt" },
        cwd = repo.root,
        on_exit = function(commit_code, commit_stderr)
          if commit_code ~= 0 then
            notify.send("Todo.txt", git_failure_message("git commit", commit_stderr), vim.log.levels.ERROR)
            return
          end
          notify.send("Todo.txt", "Pushing...")
          gitutils.job {
            args = { "push" },
            cwd = repo.root,
            on_exit = function(push_code, push_stderr)
              if push_code == 0 then
                notify.send("Todo.txt", "Pushed successfully")
              else
                notify.send("Todo.txt", git_failure_message("git push", push_stderr), vim.log.levels.ERROR)
              end
            end,
          }
        end,
      }
    end,
  }
end, { desc = "Work: push todotxt update" })

map("n", "<leader>jp", function()
  local repo = todotxt_repo()
  if not repo then
    return
  end
  gitutils.job {
    args = { "pull" },
    cwd = repo.root,
    on_exit = function(pull_code, pull_stderr)
      if pull_code == 0 then
        notify.send("Todo.txt", "Pulled successfully")
      else
        notify.send("Todo.txt", git_failure_message("git pull", pull_stderr), vim.log.levels.ERROR)
      end
    end,
  }
end, { desc = "Work: pull todotxt update" })
