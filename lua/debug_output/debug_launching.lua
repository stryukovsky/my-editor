-- High-level DAP launch selection, argument prompts, and hidden terminals.

local notify = require "configs.notify"
local debug_output_policy = require "debug_output.debug_output_policy"

local M = {}

local LANGUAGE_BY_ADAPTER = {
  java = "Java",
  ["pwa-node"] = "JavaScript / TypeScript",
  python = "Python",
  debugpy = "Python",
  go = "Go",
  codelldb = "Rust",
  scala = "Scala",
}

local function source_label(source)
  if source == "dap.configurations" then
    return "default"
  end
  if source == "dap.launch.json" then
    return "launch.json"
  end
  return source:gsub("^dap%.", "")
end

---@param config table
---@return string
local function language_label(config)
  return LANGUAGE_BY_ADAPTER[config.type] or config.type or "Unknown"
end

---@param input string
---@return string[]|nil
local function shell_split(input)
  local arguments = {}
  local current = {}
  local quote
  local escaped = false
  local started = false

  for i = 1, #input do
    local char = input:sub(i, i)
    if escaped then
      current[#current + 1] = char
      escaped = false
      started = true
    elseif char == "\\" and quote ~= "'" then
      escaped = true
      started = true
    elseif quote then
      if char == quote then
        quote = nil
      else
        current[#current + 1] = char
      end
      started = true
    elseif char == "'" or char == '"' then
      quote = char
      started = true
    elseif char:match "%s" then
      if started then
        arguments[#arguments + 1] = table.concat(current)
        current = {}
        started = false
      end
    else
      current[#current + 1] = char
      started = true
    end
  end

  if quote then
    notify.send("Debug", "Program arguments contain an unclosed quote", vim.log.levels.WARN)
    return nil
  end
  if escaped then
    current[#current + 1] = "\\"
  end
  if started then
    arguments[#arguments + 1] = table.concat(current)
  end
  return arguments
end

---@param config table
---@return table
local function resolve_program_arguments(config)
  if config.args ~= "${command:SpecifyProgramArgs}" then
    return config
  end

  local input = vim.fn.input "Program arguments: "
  local arguments = shell_split(input)
  if not arguments then
    return config
  end

  config.args = arguments
  return config
end

---@param config table
---@return integer
local function create_listed_terminal(config)
  local buf = vim.api.nvim_create_buf(true, false)
  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].buflisted = true
  vim.bo[buf].filetype = "dap-terminal"
  vim.b[buf].dap_launch_name = config.name
  return buf
end

---@param bufnr integer
---@return { config: table, source: string, language: string }[]
local function collect_configurations(bufnr)
  local dap = require "dap"
  local entries = {}
  local sources = vim.tbl_keys(dap.providers.configs)
  table.sort(sources)

  for _, source in ipairs(sources) do
    local configurations = dap.providers.configs[source](bufnr)
    if vim.islist(configurations) then
      for _, config in ipairs(configurations) do
        entries[#entries + 1] = {
          config = config,
          source = source_label(source),
          language = language_label(config),
        }
      end
    else
      notify.send("Debug", ("Configuration provider %s returned no list"):format(source), vim.log.levels.WARN)
    end
  end
  return entries
end

---@param entries { config: table, source: string, language: string }[]
local function show_picker(entries)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values
  local entry_display = require "telescope.pickers.entry_display"
  local displayer = entry_display.create {
    separator = "  ",
    items = {
      { width = 24 },
      { width = 14 },
      { remaining = true },
    },
  }

  pickers
    .new({}, {
      prompt_title = "DAP Launch Configurations",
      finder = finders.new_table {
        results = entries,
        entry_maker = function(entry)
          return {
            value = entry,
            display = function()
              return displayer {
                { entry.language, "TelescopeResultsIdentifier" },
                { entry.source, "TelescopeResultsComment" },
                { entry.config.name or "[unnamed]", "TelescopeResultsNormal" },
              }
            end,
            ordinal = table.concat({ entry.language, entry.source, entry.config.name or "" }, " "),
          }
        end,
      },
      sorter = conf.generic_sorter {},
      mappings = require "mappings.telescope.defaults",
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          local config = selection.value.config
          local config_after_policy = debug_output_policy(config)
          require("dap").run(config_after_policy, { new = true })
        end)
        return true
      end,
    })
    :find()
end

function M.setup()
  local dap = require "dap"
  dap.listeners.on_config["debug_output_arguments"] = resolve_program_arguments
  dap.defaults.fallback.terminal_win_cmd = create_listed_terminal
end

function M.launch()
  local bufnr = vim.api.nvim_get_current_buf()
  local entries = collect_configurations(bufnr)
  if #entries == 0 then
    notify.send("Debug", "No launch configurations found", vim.log.levels.WARN)
    return
  end
  show_picker(entries)
end

return M
