local M = {}
local overseer = require "overseer"

overseer.setup {
  dap = false,
  output = { use_terminal = false },
  component_aliases = {
    default = { "on_exit_set_status", "on_complete_notify", "user.log_buffer" },
  },
}

-- Store template names newest-first, independently for each project root.
local function history_path()
  return vim.fn.stdpath "data" .. "/overseer-recent.json"
end

local function load_history()
  local ok, history = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(history_path()), "\n"))
  end)
  return ok and type(history) == "table" and history or {}
end

local function recent_names(history, root)
  local names = history[root]
  return type(names) == "table" and names or {}
end

local function remember(root, name)
  local history = load_history()
  local recent = { name }
  for _, previous in ipairs(recent_names(history, root)) do
    if
      type(previous) == "string" and not vim.tbl_contains(recent, previous)
    then
      recent[#recent + 1] = previous
      if #recent == 5 then
        break
      end
    end
  end
  history[root] = recent
  local ok, err = pcall(function()
    vim.fn.mkdir(vim.fn.stdpath "data", "p")
    if vim.fn.writefile({ vim.json.encode(history) }, history_path()) ~= 0 then
      error "Cannot write task history"
    end
  end)
  if not ok then
    vim.notify(
      "Cannot save Overseer history: " .. tostring(err),
      vim.log.levels.WARN
    )
  end
end

local function recent_first(templates, root)
  local ordered, used = {}, {}
  for index, name in ipairs(recent_names(load_history(), root)) do
    if index > 5 then
      break
    end
    for i, template in ipairs(templates) do
      if template.name == name and not used[i] then
        ordered[#ordered + 1] = template
        used[i] = true
      end
    end
  end
  for i, template in ipairs(templates) do
    if not used[i] then
      ordered[#ordered + 1] = template
    end
  end
  return ordered
end

function M.pick()
  require "utils.ui_prevent_mess"()
  local root = require("configs.projects").current_root() or vim.fn.getcwd()
  local search = { dir = root, filetype = vim.bo.filetype }
  -- The built-in picker skips selection when there is only one template.
  require("overseer.template").list(search, function(templates)
    templates = vim.tbl_filter(function(template)
      return not template.hide
    end, templates)
    if #templates == 0 then
      vim.notify("No project tasks found", vim.log.levels.INFO)
      return
    end
    templates = recent_first(templates, root)
    vim.ui.select(templates, {
      prompt = "Project tasks:",
      kind = "overseer_template",
      format_item = function(template)
        return template.desc and (template.name .. " — " .. template.desc)
          or template.name
      end,
    }, function(template)
      if not template then
        return
      end
      -- Leave the Telescope float before opening the job log.
      vim.schedule(function()
        overseer.run_task(
          { name = template.name, search_params = search },
          function(task, err)
            if not task then
              vim.notify(err or "Cannot create task", vim.log.levels.ERROR)
              return
            end
            remember(root, template.name)
          end
        )
      end)
    end)
  end)
end

return M
