local M = {}

function M.preview(entry)
  local lines = { entry.name .. " — " .. entry.adapter, "" }
  if entry.backend then
    lines[#lines + 1] = "Launch requires the "
      .. entry.backend
      .. " LSP connection."
  end
  if entry.command then
    lines[#lines + 1] = "Executable: " .. entry.command
  end
  lines[#lines + 1] = "Project root: " .. entry.root
  lines[#lines + 1] = "Matched identifiers: "
    .. (#entry.matches > 0 and table.concat(entry.matches, ", ") or "none")
  vim.list_extend(lines, { "", "Predefined debuggee configurations:", "" })
  local configs = require("dap_tools.catalog").configurations(entry)
  for _, ft in ipairs(entry.filetypes) do
    if #configs[ft] > 0 then
      lines[#lines + 1] = "[" .. ft .. "]"
      vim.list_extend(lines, vim.split(vim.inspect(configs[ft]), "\n"))
      lines[#lines + 1] = ""
    end
  end
  return lines
end

function M.open()
  local project = require "dap_tools.project"
  local root, bufnr = project.root(), vim.api.nvim_get_current_buf()
  local ok, files = pcall(project.files, root)
  if not ok then
    require("integrations.notify").send(
      "DAP activation",
      tostring(files),
      vim.log.levels.ERROR
    )
    return
  end
  local entries = project.rank(root, files)
  local matched = 0
  for index, entry in ipairs(entries) do
    entry.index = index
    matched = matched + (entry.score > 0 and 1 or 0)
  end
  local keep_open = matched > 1
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values
  local base = conf.generic_sorter {}
  local sorter = require("telescope.sorters").Sorter:new {
    discard = false,
    init = function()
      base:_init()
    end,
    destroy = function()
      base:_destroy()
    end,
    start = function(_, prompt)
      base:_start(prompt)
    end,
    scoring_function = function(_, prompt, line, entry)
      local score = prompt == "" and 0
        or base:scoring_function(prompt, line, entry)
      return score < 0 and -1 or entry.value.index + score / (1 + score)
    end,
    highlighter = function(_, prompt, display)
      return base.highlighter and base:highlighter(prompt, display) or {}
    end,
  }
  local finder = require("telescope.finders").new_table {
    results = entries,
    entry_maker = function(entry)
      return {
        value = entry,
        ordinal = entry.name
          .. " "
          .. entry.adapter
          .. " "
          .. (entry.backend or ""),
        display = function()
          local active = require("dap_tools").active[entry.id]
              and " [activated]"
            or ""
          return (entry.score > 0 and "* " or "  ")
            .. entry.name
            .. " ("
            .. entry.adapter
            .. ")"
            .. active
        end,
      }
    end,
  }
  require "moonshine.utils.ui_prevent_mess"()
  local picker
  picker = require("telescope.pickers").new({}, {
    prompt_title = "Activate DAP adapter",
    results_title = keep_open
        and "Project matches first · Enter activates · q closes"
      or "Project matches first · Enter activates",
    initial_mode = "normal",
    sorting_strategy = "ascending",
    finder = finder,
    sorter = sorter,
    mappings = require "mappings.telescope.defaults",
    previewer = require("telescope.previewers").new_buffer_previewer {
      title = "Debuggee configurations",
      define_preview = function(self, entry)
        vim.api.nvim_buf_set_lines(
          self.state.bufnr,
          0,
          -1,
          false,
          M.preview(entry.value)
        )
      end,
    },
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        if not selection then
          return
        end
        local entry = selection.value
        if
          require("dap_tools").activate(
            entry.id,
            { root = entry.root, project_root = root, bufnr = bufnr }
          )
        then
          if keep_open then
            picker:refresh(finder, { reset_prompt = false })
          else
            actions.close(prompt_bufnr)
          end
        end
      end)
      return true
    end,
  })
  picker:find()
  return picker
end

return M
