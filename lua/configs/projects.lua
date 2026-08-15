local notify = require "configs.notify"

local M = {}

local function state_path()
  return vim.fn.stdpath "data" .. "/projects.json"
end

---@param path? string
---@return string|nil
function M.normalize(path)
  if not path or path == "" then
    return nil
  end
  path = vim.fn.expand(path)
  if path == "" then
    return nil
  end
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  path = path:gsub("/+$", "")
  return path ~= "" and path or nil
end

---@param path string
---@return string
function M.display_path(path)
  return vim.fn.fnamemodify(path, ":~")
end

---@param path string
---@return string
function M.name(path)
  local name = vim.fn.fnamemodify(path, ":t")
  return name ~= "" and name or path
end

---@return string|nil
function M.current_root()
  local tab = vim.api.nvim_get_current_tabpage()
  local ok, manager = pcall(require, "neo-tree.sources.manager")
  if ok then
    local state = manager.get_state("filesystem", tab)
    if state and state.path and state.path ~= "" then
      return M.normalize(state.path)
    end
    state = manager.get_state "filesystem"
    if state and state.path and state.path ~= "" then
      return M.normalize(state.path)
    end
  end
  return M.normalize(vim.fn.getcwd())
end

---@return string[]
function M.load()
  local file = state_path()
  if vim.fn.filereadable(file) == 0 then
    return {}
  end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
  if not ok or type(data) ~= "table" then
    return {}
  end
  local list = data.projects or data
  local projects = {}
  local seen = {}
  for _, item in ipairs(list) do
    local path = type(item) == "string" and item or item.path
    path = M.normalize(path)
    if path and not seen[path] then
      seen[path] = true
      projects[#projects + 1] = path
    end
  end
  return projects
end

---@param projects string[]
function M.save(projects)
  vim.fn.mkdir(vim.fn.stdpath "data", "p")
  vim.fn.writefile({ vim.json.encode { projects = projects } }, state_path())
end

---@param path string
---@return boolean
function M.is_marked(path)
  path = M.normalize(path)
  return path ~= nil and vim.list_contains(M.load(), path)
end

---@param path string
local function bump(path)
  local projects = M.load()
  for i, existing in ipairs(projects) do
    if existing == path then
      table.remove(projects, i)
      break
    end
  end
  table.insert(projects, 1, path)
  M.save(projects)
end

---@param tab? integer
---@return string|nil
function M.tab_project(tab)
  tab = tab or vim.api.nvim_get_current_tabpage()
  local ok, path = pcall(function()
    return vim.t[tab].project_path
  end)
  if ok and type(path) == "string" and path ~= "" then
    return M.normalize(path)
  end
  return nil
end

---@param path string
---@return integer|nil
function M.find_tab(path)
  path = M.normalize(path)
  if not path then
    return nil
  end
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if M.tab_project(tab) == path then
      return tab
    end
  end
  return nil
end

---@return { path: string, tab: integer }[]
function M.open_tabs()
  local items = {}
  local seen = {}
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if not (_G.codediff_tabpages and _G.codediff_tabpages[tab]) then
      local path = M.tab_project(tab)
      if path and not seen[path] then
        seen[path] = true
        items[#items + 1] = { path = path, tab = tab }
      end
    end
  end
  return items
end

---@param path string
function M.apply_tab(path)
  path = M.normalize(path)
  if not path then
    return
  end
  vim.api.nvim_cmd({ cmd = "tcd", args = { path } }, {})
  vim.t.project_path = path
end

local function tab_is_reusable()
  if M.tab_project() then
    return false
  end
  if require "utils.is_codediff_tab"() then
    return false
  end
  return require "utils.is_buffer_initial_dashboard"()
end

---@param path string
function M.open(path)
  path = M.normalize(path)
  if not path or vim.fn.isdirectory(path) == 0 then
    notify.send("Projects", "Project directory missing: " .. M.display_path(path or ""), vim.log.levels.ERROR)
    return
  end
  bump(path)
  local existing = M.find_tab(path)
  if existing then
    vim.api.nvim_set_current_tabpage(existing)
    M.apply_tab(path)
    return
  end
  if not tab_is_reusable() then
    vim.cmd.tabnew()
  end
  M.apply_tab(path)
end

function M.mark()
  local path = M.current_root()
  if not path or vim.fn.isdirectory(path) == 0 then
    notify.send("Projects", "Not a directory: " .. tostring(path), vim.log.levels.ERROR)
    return
  end
  if M.is_marked(path) then
    vim.t.project_path = path
    M.apply_tab(path)
    notify.send("Projects", "Already a project: " .. M.display_path(path), vim.log.levels.INFO)
    return
  end
  bump(path)
  M.apply_tab(path)
  notify.send("Projects", "Marked " .. M.display_path(path), vim.log.levels.INFO)
end

---@param path string
function M.unmark(path)
  path = M.normalize(path)
  if not path then
    return
  end
  local projects = M.load()
  local removed = false
  for i, existing in ipairs(projects) do
    if existing == path then
      table.remove(projects, i)
      removed = true
      break
    end
  end
  if not removed then
    return
  end
  M.save(projects)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if M.tab_project(tab) == path then
      vim.t[tab].project_path = nil
    end
  end
  notify.send("Projects", "Unmarked " .. M.display_path(path), vim.log.levels.INFO)
end

---@param item { path: string, tab?: integer }
local function preview_lines(item)
  local path = item.path
  local lines = {
    "Name:    " .. M.name(path),
    "Path:    " .. M.display_path(path),
  }
  if path ~= M.display_path(path) then
    lines[#lines + 1] = "Abs:     " .. path
  end
  local tab = item.tab or M.find_tab(path)
  if tab then
    lines[#lines + 1] = "Tab:     " .. tostring(vim.api.nvim_tabpage_get_number(tab)) .. " (open)"
  else
    lines[#lines + 1] = "Tab:     not open"
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Contents:"
  local entries = vim.fn.isdirectory(path) == 1 and vim.fn.readdir(path) or {}
  table.sort(entries)
  if #entries == 0 then
    lines[#lines + 1] = "  (empty or unreadable)"
  else
    for i, name in ipairs(entries) do
      if i > 40 then
        lines[#lines + 1] = "  …"
        break
      end
      lines[#lines + 1] = "  " .. name
    end
  end
  return lines
end

---@param opts { title: string, items: { path: string, tab?: integer }[], empty: string, on_select: fun(item: { path: string, tab?: integer }), unmark?: boolean }
local function open_picker(opts)
  if #opts.items == 0 then
    notify.send("Projects", opts.empty, vim.log.levels.WARN)
    return
  end

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local previewers = require "telescope.previewers"
  local entry_display = require "telescope.pickers.entry_display"

  local displayer = entry_display.create {
    separator = "  ",
    items = {
      { width = 24 },
      { remaining = true },
    },
  }

  local function entry_maker(item)
    local open = item.tab ~= nil or M.find_tab(item.path) ~= nil
    return {
      value = item,
      ordinal = M.name(item.path) .. " " .. M.display_path(item.path),
      display = function()
        local name = M.name(item.path)
        if open then
          name = name .. "  [open]"
        end
        return displayer {
          { name, open and "TelescopeResultsIdentifier" or "TelescopeResultsNormal" },
          { M.display_path(item.path), "TelescopeResultsComment" },
        }
      end,
    }
  end

  pickers
    .new({
      initial_mode = "normal",
    }, {
      prompt_title = opts.title,
      finder = finders.new_table {
        results = opts.items,
        entry_maker = entry_maker,
      },
      sorter = conf.generic_sorter {},
      previewer = previewers.new_buffer_previewer {
        title = "Project",
        define_preview = function(self, entry)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, preview_lines(entry.value))
        end,
      },
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value then
            opts.on_select(selection.value)
          end
        end)
        if opts.unmark then
          local function unmark_selected()
            local selection = action_state.get_selected_entry()
            if not selection or not selection.value then
              return
            end
            M.unmark(selection.value.path)
            local picker = action_state.get_current_picker(prompt_bufnr)
            local next_items = {}
            for _, path in ipairs(M.load()) do
              next_items[#next_items + 1] = { path = path, tab = M.find_tab(path) }
            end
            if #next_items == 0 then
              actions.close(prompt_bufnr)
              return
            end
            picker:refresh(
              finders.new_table {
                results = next_items,
                entry_maker = entry_maker,
              },
              { reset_prompt = false }
            )
          end
          map("n", "d", unmark_selected)
          map("i", "<C-d>", unmark_selected)
        end
        return true
      end,
    })
    :find()
end

function M.picker_all()
  local items = {}
  for _, path in ipairs(M.load()) do
    items[#items + 1] = { path = path, tab = M.find_tab(path) }
  end
  open_picker {
    title = "Projects",
    items = items,
    empty = "No projects yet. Mark one with <leader>prj",
    unmark = true,
    on_select = function(item)
      M.open(item.path)
    end,
  }
end

function M.picker_open()
  open_picker {
    title = "Open project tabs",
    items = M.open_tabs(),
    empty = "No project tabs. Open one with <A-P> or mark with <leader>prj",
    on_select = function(item)
      if item.tab and vim.api.nvim_tabpage_is_valid(item.tab) then
        vim.api.nvim_set_current_tabpage(item.tab)
        M.apply_tab(item.path)
      else
        M.open(item.path)
      end
    end,
  }
end

function M.setup()
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      local cwd = M.normalize(vim.fn.getcwd())
      if cwd and M.is_marked(cwd) then
        vim.t.project_path = cwd
      end
    end,
  })
end

M.setup()

return M
