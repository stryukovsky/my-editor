-- Marked project directories. Opening one is a terminal workspace, not a Neovim tab.
--
-- Data: ~/.config/nvim/data/projects.json (because stdpath("data") is patched).
-- Mark with <leader>prj, pick with <A-P>.
--
-- Algorithm — is this project already open in Kitty?
--   Ask Kitty once for all tabs (`kitten @ ls` → id, title, cwd).
--   For each saved project path, pick the best tab:
--     1. title == folder name AND cwd == project path   (exact, stop)
--     2. title == folder name                           (we set --tab-title to the dirname)
--     3. cwd == project path                            (title drifted / never set)
--   Two folders with the same basename can collide on step 2.
--
-- Algorithm — open / focus:
--   bump recency in projects.json
--   in Kitty: focus a matching tab, or launch a new tab
--   in Ghostty: launch a new terminal window

local notify = require "configs.notify"
local terminal = require "utils.terminal"

local M = {}

-- Path of the saved project list under the patched stdpath("data").
local function state_path()
  return vim.fn.stdpath "data" .. "/projects.json"
end

-- Expand ~, make absolute, strip trailing slashes. nil if empty/invalid.
---@param path? string
---@return string|nil
function M.normalize(path)
  if not path or path == "" then
    return nil
  end
  local expanded = vim.fn.expand(path)
  if expanded == "" then
    return nil
  end
  local abs = vim.fs.normalize(vim.fn.fnamemodify(expanded, ":p")):gsub("/+$", "")
  if abs == "" then
    return nil
  end
  return abs
end

-- Home-relative form for picker rows (`~/src/foo`).
---@param path string
---@return string
function M.display_path(path)
  return vim.fn.fnamemodify(path, ":~")
end

-- Last path component — this is the Kitty `--tab-title` we set on launch.
---@param path string
---@return string
function M.name(path)
  local name = vim.fn.fnamemodify(path, ":t")
  return name ~= "" and name or path
end

-- Directory this Neovim thinks it is in: neo-tree root if any, else getcwd.
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

-- Read projects.json, normalize paths, drop dupes. Order is recency (front = newest).
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
    local raw = type(item) == "string" and item or item.path
    local path = M.normalize(raw)
    if path and not seen[path] then
      seen[path] = true
      projects[#projects + 1] = path
    end
  end
  return projects
end

-- Write the list back as `{ "projects": [ ... ] }`.
---@param projects string[]
function M.save(projects)
  vim.fn.mkdir(vim.fn.stdpath "data", "p")
  vim.fn.writefile({ vim.json.encode { projects = projects } }, state_path())
end

-- True if this directory is already in the saved list.
---@param path string
---@return boolean
function M.is_marked(path)
  local normalized = M.normalize(path)
  return normalized ~= nil and vim.list_contains(M.load(), normalized)
end

-- Move path to index 1 so the next picker open shows it first, then save.
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

-- Project bound to this Neovim tabpage (vim.t.project_path). Python setup still reads this.
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

-- `:tcd` this Neovim to the project and remember it on the Neovim tab. No Kitty involved.
---@param path string
function M.apply_cwd(path)
  local normalized = M.normalize(path)
  if not normalized then
    return
  end
  vim.api.nvim_cmd({ cmd = "tcd", args = { normalized } }, {})
  vim.t.project_path = normalized
end

-- Match one project path against Kitty tabs. Pass `tabs` to reuse a single `ls`.
-- Returns the best tab (title+cwd, else title, else cwd) or nil.
---@param path string
---@param tabs? KittenTab[]
---@return KittenTab|nil
function M.kitty_tab(path, tabs)
  local normalized = M.normalize(path)
  if not normalized then
    return nil
  end
  local name = M.name(normalized)
  ---@type KittenTab|nil
  local named
  ---@type KittenTab|nil
  local cwd_match
  for _, tab in ipairs(tabs or require("configs.kitten").tabs()) do
    local tab_cwd = tab.cwd and M.normalize(tab.cwd) or nil
    -- Title + cwd: unambiguous.
    if tab.title == name and tab_cwd == normalized then
      return tab
    end
    -- Title only: we launched with --tab-title=<dirname>.
    if tab.title == name then
      named = named or tab
    end
    -- Cwd only: tab title drifted (nvim sets window title, user renamed, …).
    if tab_cwd == normalized then
      cwd_match = cwd_match or tab
    end
  end
  return named or cwd_match
end

-- In Kitty, focus an existing project tab or launch a new one. In Ghostty, launch a new window.
---@param path string
function M.open(path)
  local normalized = M.normalize(path)
  if not normalized or vim.fn.isdirectory(normalized) == 0 then
    notify.send("Projects", "Project directory missing: " .. M.display_path(normalized or path or ""), vim.log.levels.ERROR)
    return
  end
  bump(normalized)
  if terminal.is_kitty() then
    local existing = M.kitty_tab(normalized)
    if existing then
      require("configs.kitten").focus_tab(existing.id)
      return
    end
  end

  terminal.open(normalized, {
    tab_title = M.name(normalized),
  })
end

-- Remember current_root() as a project and tcd this Neovim there. Does not open Kitty.
function M.mark()
  local path = M.current_root()
  if not path or vim.fn.isdirectory(path) == 0 then
    notify.send("Projects", "Not a directory: " .. tostring(path), vim.log.levels.ERROR)
    return
  end
  if M.is_marked(path) then
    M.apply_cwd(path)
    notify.send("Projects", "Already a project: " .. M.display_path(path), vim.log.levels.INFO)
    return
  end
  bump(path)
  M.apply_cwd(path)
  notify.send("Projects", "Marked " .. M.display_path(path), vim.log.levels.INFO)
end

-- Drop path from projects.json. Kitty tabs are left alone.
---@param path string
function M.unmark(path)
  local normalized = M.normalize(path)
  if not normalized then
    return
  end
  local projects = M.load()
  local removed = false
  for i, existing in ipairs(projects) do
    if existing == normalized then
      table.remove(projects, i)
      removed = true
      break
    end
  end
  if not removed then
    return
  end
  M.save(projects)
  if M.tab_project() == normalized then
    vim.t.project_path = nil
  end
  notify.send("Projects", "Unmarked " .. M.display_path(normalized), vim.log.levels.INFO)
end

-- Text for the Telescope preview pane: name, path, Kitty tab id, directory listing.
---@param item { path: string, tab?: KittenTab }
local function preview_lines(item)
  local path = item.path
  local lines = {
    "Name:    " .. M.name(path),
    "Path:    " .. M.display_path(path),
  }
  if path ~= M.display_path(path) then
    lines[#lines + 1] = "Abs:     " .. path
  end
  if item.tab then
    lines[#lines + 1] = "Kitty:   tab " .. tostring(item.tab.id) .. " (open)"
  else
    lines[#lines + 1] = "Kitty:   not open"
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

-- Generic Telescope list of projects. Enter → on_select; `d` unmarks when enabled.
---@param opts { title: string, items: { path: string, tab?: KittenTab }[], empty: string, on_select: fun(item: { path: string, tab?: KittenTab }), unmark?: boolean }
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

  -- One picker row: folder name, optional [open], and the home-relative path.
  local function entry_maker(item)
    local open = item.tab ~= nil
    return {
      value = item,
      ordinal = M.name(item.path) .. " " .. M.display_path(item.path),
      display = function()
        local name = M.name(item.path)
        if open then
          -- Kitty already has a tab for this folder; select focuses it by id.
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
          -- Remove from projects.json and rebuild the list without leaving Telescope.
          local function unmark_selected()
            local selection = action_state.get_selected_entry()
            if not selection or not selection.value then
              return
            end
            M.unmark(selection.value.path)
            local picker = action_state.get_current_picker(prompt_bufnr)
            local next_items = {}
            local tabs = require("configs.kitten").tabs()
            for _, path in ipairs(M.load()) do
              next_items[#next_items + 1] = { path = path, tab = M.kitty_tab(path, tabs) }
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

-- <A-P>: one `kitten @ ls`, tag each saved project with its tab, then open the picker.
function M.picker_all()
  local items = {}
  local tabs = require("configs.kitten").tabs()
  for _, path in ipairs(M.load()) do
    items[#items + 1] = { path = path, tab = M.kitty_tab(path, tabs) }
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

-- On startup, if cwd is a marked project, stamp vim.t.project_path for this Neovim.
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
