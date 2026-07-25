local map = require "mappings.map"
local todotxt = require "todotxt"

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
  local text = line
    :gsub("%+%S+", "")
    :gsub("%s+", " ")
    :gsub("^%s+", "")
    :gsub("%s+$", "")
    :gsub("|", "\\|")
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
      vim.notify("todotxt path not configured or unreadable", vim.log.levels.WARN)
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
    vim.notify("No tasks to preview", vim.log.levels.INFO)
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
  local separator = "| " .. table.concat(vim.tbl_map(function()
    return "---"
  end, proj_names), " | ") .. " |"

  local md = { header, separator }
  for row = 1, max_rows do
    local cells = {}
    for _, name in ipairs(proj_names) do
      table.insert(cells, columns[name][row] or "")
    end
    table.insert(md, "| " .. table.concat(cells, " | ") .. " |")
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "todotxt-preview"
  vim.bo[buf].buftype = ""
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, md)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  vim.bo[buf].buflisted = true

  -- Name without .md so filetype detection does not overwrite todotxt-preview.
  local ok = pcall(vim.api.nvim_buf_set_name, buf, "todotxt-preview")
  if not ok then
    vim.api.nvim_buf_set_name(buf, "todotxt-preview-" .. math.random(9999))
  end
  vim.bo[buf].filetype = "todotxt-preview"

  vim.api.nvim_set_current_buf(buf)
end, { desc = "Work: markdown table preview by project" })

map("n", "<leader>jc", function()
  todotxt.cycle_priority()
end, { desc = "Work: cycle priority" })

map("n", "<leader>jtd", function() end, { desc = "Work: today date" })

map("n", "<leader>jtm", function() end, { desc = "Work: tomorrow date" })

map("n", "<leader>jx", function()
  todotxt.toggle_todo_state()
end, { desc = "Work: toggle todo state" })
map("n", "<leader>jP", function()
  local todotxt_file = todotxt.config.todotxt
  if not todotxt_file then
    vim.notify("todotxt path not configured", vim.log.levels.WARN)
    return
  end
  local parent = vim.fn.fnamemodify(todotxt_file, ":h")
  local git_root = vim.fn.systemlist { "git", "-C", parent, "rev-parse", "--show-toplevel" }
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repo: " .. parent, vim.log.levels.WARN)
    return
  end
  -- compute path relative to git root
  local relpath = vim.fn.systemlist { "git", "-C", parent, "ls-files", "--full-name", todotxt_file }
  if vim.v.shell_error ~= 0 or #relpath == 0 or relpath[1] == "" then
    -- maybe the file is not tracked yet — fall back to basename
    relpath = { vim.fn.fnamemodify(todotxt_file, ":t") }
  end
  vim.fn.jobstart({ "git", "-C", git_root[1], "add", relpath[1] }, {
    on_stderr = function(_, data)
      if data then
        vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, add_code)
      if add_code ~= 0 then
        vim.notify("git add failed", vim.log.levels.ERROR)
        return
      end
      vim.fn.jobstart({ "git", "-C", git_root[1], "commit", "-m", "update todotxt" }, {
        on_exit = function(_, commit_code)
          if commit_code ~= 0 then
            vim.notify("git commit failed", vim.log.levels.ERROR)
            return
          end
          vim.fn.jobstart({ "git", "-C", git_root[1], "push" }, {
            on_exit = function(_, push_code)
              if push_code == 0 then
                vim.notify("todotxt pushed successfully", vim.log.levels.INFO)
              else
                vim.notify("git push failed", vim.log.levels.ERROR)
              end
            end,
          })
        end,
      })
    end,
  })
end, { desc = "Work: push todotxt update" })

map("n", "<leader>jp", function()
  local todotxt_file = todotxt.config.todotxt
  if not todotxt_file then
    vim.notify("todotxt path not configured", vim.log.levels.WARN)
    return
  end
  local parent = vim.fn.fnamemodify(todotxt_file, ":h")
  local git_root = vim.fn.systemlist { "git", "-C", parent, "rev-parse", "--show-toplevel" }
  if vim.v.shell_error ~= 0 then
    vim.notify("Not a git repo: " .. parent, vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ "git", "-C", git_root[1], "pull" }, {
    on_stderr = function(_, data)
      if data then
        vim.notify(table.concat(data, "\n"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, pull_code)
      if pull_code == 0 then
        vim.notify("todotxt pulled successfully", vim.log.levels.INFO)
      else
        vim.notify("git pull failed", vim.log.levels.ERROR)
      end
    end,
  })
end, { desc = "Work: pull todotxt update" })
