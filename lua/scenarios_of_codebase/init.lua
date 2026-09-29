local notify = require "configs.notify"

local M = {
  active = nil,
  last = nil,
  playback_index = 0,
  virtual_text_buffer = nil,
}

local function trim(value)
  return (value:gsub("^%s*(.-)%s*$", "%1"))
end

local function join_path(...)
  return table.concat({ ... }, "/"):gsub("//+", "/")
end

local function current_cwd()
  return vim.fn.fnamemodify(vim.fn.getcwd(), ":p"):gsub("/$", "")
end

local function state_dir()
  return join_path(vim.fn.stdpath "data", "scenarios_of_codebase")
end

local function project_dir(cwd)
  return join_path(cwd, ".scenarios_of_codebase")
end

local function prompt_path()
  return join_path(vim.fn.stdpath "config", "ai/scenarios/prompt.txt")
end

local function slugify(name)
  local slug = name:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
  return slug
end

local function scenario_files(directory)
  return vim.fn.globpath(directory, "*.txt", false, true)
end

local function parse_scenario(path)
  local lines = vim.fn.readfile(path)
  if #lines < 2 or trim(lines[1]) == "" or trim(lines[2]) == "" then
    return nil
  end

  local points = {}
  for index = 3, #lines, 2 do
    local position = trim(lines[index] or "")
    local description = trim(lines[index + 1] or "")
    if position ~= "" then
      table.insert(points, {
        position = position,
        description = description,
      })
    end
  end

  return {
    path = path,
    cwd = trim(lines[1]),
    name = trim(lines[2]),
    points = points,
    lines = lines,
  }
end

local function location_at_cursor()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    notify.send("Scenarios", "Save the current buffer before adding it to a scenario", vim.log.levels.WARN)
    return nil
  end

  path = vim.fn.fnamemodify(path, ":p")
  local cwd = current_cwd()
  if path:sub(1, #cwd + 1) == cwd .. "/" then
    path = path:sub(#cwd + 2)
  end
  return ("%s:%d"):format(path, vim.api.nvim_win_get_cursor(0)[1])
end

local function resolve_location(scenario, location)
  local file, line = location:match "^(.-):(%d+)$"
  file = file or location
  local path = file:sub(1, 1) == "/" and file or join_path(scenario.cwd, file)
  return path, tonumber(line) or 1
end

local function jump(scenario, location)
  local path, line = resolve_location(scenario, location)
  if vim.fn.filereadable(path) ~= 1 then
    notify.send("Scenarios", "File no longer exists: " .. path, vim.log.levels.WARN)
    return false
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
  vim.api.nvim_win_set_cursor(0, { math.min(line, vim.api.nvim_buf_line_count(0)), 0 })
  return true
end

local scenario_namespace = vim.api.nvim_create_namespace "scenarios_of_codebase"

local function description_virtual_lines(description)
  local lines = {}
  local length = vim.fn.strchars(description)
  for offset = 0, length - 1, 80 do
    table.insert(lines, { { trim(vim.fn.strcharpart(description, offset, 80)), "Comment" } })
  end
  return lines
end

local function clear_virtual_text()
  if M.virtual_text_buffer and vim.api.nvim_buf_is_valid(M.virtual_text_buffer) then
    vim.api.nvim_buf_clear_namespace(M.virtual_text_buffer, scenario_namespace, 0, -1)
  end
  M.virtual_text_buffer = nil
end

local function show_description(description)
  clear_virtual_text()
  if description == "" then
    return
  end

  local buffer = vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1] - 1
  vim.api.nvim_buf_set_extmark(buffer, scenario_namespace, row, 0, {
    virt_lines = description_virtual_lines(description),
    virt_lines_above = true,
  })
  M.virtual_text_buffer = buffer
end

local function select_scenario(scenario)
  M.active = scenario
  M.last = scenario
  M.playback_index = 0
  notify.send("Scenarios", "Selected: " .. scenario.name)
  local first_point = scenario.points[1]
  if first_point and jump(scenario, first_point.position) then
    M.playback_index = 1
    show_description(first_point.description)
  end
end

function M.create()
  local cwd = current_cwd()
  vim.ui.select({
    { label = "Project (.scenarios_of_codebase)", directory = project_dir(cwd) },
    { label = "Neovim state", directory = state_dir() },
  }, {
    prompt = "Store scenario in",
    format_item = function(item)
      return item.label
    end,
  }, function(storage)
    if not storage then
      return
    end
    vim.ui.input({ prompt = "Scenario name: " }, function(name)
      name = name and trim(name) or ""
      local slug = slugify(name)
      if slug == "" then
        notify.send("Scenarios", "Scenario name must include letters or numbers", vim.log.levels.WARN)
        return
      end

      vim.fn.mkdir(storage.directory, "p")
      local path = join_path(storage.directory, slug .. ".txt")
      local suffix = 2
      while vim.uv.fs_stat(path) do
        path = join_path(storage.directory, ("%s-%d.txt"):format(slug, suffix))
        suffix = suffix + 1
      end

      vim.fn.writefile({ cwd, name }, path)
      select_scenario(parse_scenario(path))
      notify.send("Scenarios", "Created: " .. vim.fn.fnamemodify(path, ":t"))
    end)
  end)
end

function M.append()
  if not M.active then
    notify.send("Scenarios", "Select a scenario first with <leader>scv", vim.log.levels.WARN)
    return
  end

  local location = location_at_cursor()
  if not location then
    return
  end
  vim.ui.input({ prompt = "Point description (max 60 characters): " }, function(description)
    description = description and trim(description) or ""
    if description == "" then
      notify.send("Scenarios", "Point description cannot be empty", vim.log.levels.WARN)
      return
    end
    if vim.str_utfindex(description) > 60 then
      notify.send("Scenarios", "Point description must be 60 characters or fewer", vim.log.levels.WARN)
      return
    end
    vim.fn.writefile({ location, description }, M.active.path, "a")
    table.insert(M.active.points, { position = location, description = description })
    M.playback_index = 0
    notify.send("Scenarios", "Added point")
  end)
end

function M.view()
  local cwd = current_cwd()
  local scenarios = {}
  for _, path in ipairs(scenario_files(project_dir(cwd))) do
    local scenario = parse_scenario(path)
    if scenario then
      table.insert(scenarios, scenario)
    end
  end
  for _, path in ipairs(scenario_files(state_dir())) do
    local scenario = parse_scenario(path)
    if scenario and scenario.cwd == cwd then
      table.insert(scenarios, scenario)
    end
  end
  table.sort(scenarios, function(a, b)
    return a.name:lower() < b.name:lower()
  end)

  if #scenarios == 0 then
    notify.send("Scenarios", "No scenarios for " .. cwd)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values
  local previewers = require "telescope.previewers"

  require("utils.ui_prevent_mess")()
  pickers
    .new({}, {
      prompt_title = "Codebase Scenarios",
      initial_mode = "normal",
      finder = finders.new_table {
        results = scenarios,
        entry_maker = function(scenario)
          local is_current = M.active and M.active.path == scenario.path
          return {
            value = scenario,
            display = scenario.name .. (is_current and "  [current]" or ""),
            ordinal = scenario.name,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, entry.value.lines)
          vim.bo[self.state.bufnr].filetype = "text"
        end,
      },
      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          select_scenario(selection.value)
        end)
        return true
      end,
    })
    :find()
end

function M.next()
  if not M.active then
    notify.send("Scenarios", "Select a scenario first with <leader>scv", vim.log.levels.WARN)
    return
  end
  local points = M.active.points
  if #points == 0 then
    notify.send("Scenarios", "Selected scenario has no points", vim.log.levels.WARN)
    return
  end
  if M.playback_index >= #points then
    M.last = M.active
    M.active = nil
    M.playback_index = 0
    notify.send("Scenarios", "Scenario has ended. To play again, press <leader>scr")
    return
  end
  M.playback_index = M.playback_index + 1
  local point = points[M.playback_index]
  if jump(M.active, point.position) then
    show_description(point.description)
  end
end

function M.previous()
  if not M.active then
    notify.send("Scenarios", "Select a scenario first with <leader>scv", vim.log.levels.WARN)
    return
  end
  local points = M.active.points
  if M.playback_index > #points then
    M.playback_index = #points
  else
    M.playback_index = math.max(1, M.playback_index - 1)
  end
  local point = points[M.playback_index]
  if point and jump(M.active, point.position) then
    show_description(point.description)
  end
end

function M.replay()
  if not M.active and not M.last then
    notify.send("Scenarios", "Select a scenario first with <leader>scv", vim.log.levels.WARN)
    return
  end
  M.active = M.active or M.last
  M.playback_index = 0
  M.next()
end

function M.quit()
  clear_virtual_text()
  M.active = nil
  M.last = nil
  M.playback_index = 0
end

function M.yank_prompt()
  local path = prompt_path()
  if vim.fn.filereadable(path) ~= 1 then
    notify.send("Scenarios", "Scenario prompt is missing: " .. path, vim.log.levels.ERROR)
    return
  end
  local prompt = table.concat(vim.fn.readfile(path), "\n")
  if M.active then
    prompt = (
      "%s\n\nCheck whether this file exists and contains content. If it does, clear the file, then write the scenario to it:\n%s"
    ):format(prompt, M.active.path)
  end
  vim.fn.setreg("+", prompt)
  notify.send("Scenarios", "Scenario prompt copied to clipboard")
end

return M
