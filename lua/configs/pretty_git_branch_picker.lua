-- Custom git-branch picker (does not replace telescope.builtin.git_branches).

local display = require "configs.git_display"

local LOG_SEP = "\1"

-- git log --graph line: `<graph><hash>\1<decorations>\1<subject>\1<relative date>`
---@param line string
---@return string
local function format_log_line(line)
  local graph, hash, payload = line:match("^(.-)([0-9a-fA-F]+)" .. LOG_SEP .. "(.*)$")
  if not hash then
    return line
  end
  local parts = vim.split(payload, LOG_SEP, { plain = true })
  local deco = vim.trim(parts[1] or "")
  local subject = display.truncate_subject(parts[2] or "")
  local date = parts[3] or ""
  if deco ~= "" then
    return string.format("%s%s - %s %s (%s)", graph, hash, deco, subject, date)
  end
  return string.format("%s%s - %s (%s)", graph, hash, subject, date)
end

local preview_ns = vim.api.nvim_create_namespace "pretty_git_branch_picker.preview"

---@param bufnr integer
---@param content string[]
local function highlight_log_buffer(bufnr, content)
  local hl = vim.hl
  for i = 1, #content do
    local line = content[i]
    local hstart, hend = line:find "[0-9a-fA-F]+"
    if hstart and hend < #line then
      pcall(hl.range, bufnr, preview_ns, "TelescopeResultsIdentifier", { i - 1, hstart - 1 }, { i - 1, hend })
    end
    local _, cstart = line:find "- %("
    if cstart then
      local cend = string.find(line, "%) ")
      if cend then
        pcall(hl.range, bufnr, preview_ns, "TelescopeResultsConstant", { i - 1, cstart - 1 }, { i - 1, cend })
      end
    end
    local dstart = line:find " %(%d"
    if dstart then
      pcall(hl.range, bufnr, preview_ns, "TelescopeResultsSpecialComment", { i - 1, dstart }, { #line })
    end
  end
end

---@param opts table
---@return table
local function branch_log_previewer(opts)
  local previewers = require "telescope.previewers"
  local putils = require "telescope.previewers.utils"
  local git_command = require("telescope.utils").__git_command

  return previewers.new_buffer_previewer {
    title = "Git Branch Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,
    define_preview = function(self, entry)
      local cmd = git_command({
        "--no-pager",
        "log",
        "--graph",
        "--max-count=1000",
        "--pretty=format:%h%x01%d%x01%s%x01%cr",
        "--abbrev-commit",
        "--date=relative",
        entry.value,
      }, opts)

      putils.job_maker(cmd, self.state.bufnr, {
        value = entry.value,
        bufname = self.state.bufname,
        cwd = opts.cwd,
        callback = function(bufnr, content)
          if not content then
            return
          end
          local lines = {}
          for i, raw in ipairs(content) do
            lines[i] = format_log_line(raw)
          end
          vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
          highlight_log_buffer(bufnr, lines)
        end,
      })
    end,
  }
end

---@param opts? table
local function pretty_git_branch_picker(opts)
  opts = vim.tbl_deep_extend("force", {
    wrap_results = true,
    initial_mode = "normal",
    layout_config = {
      horizontal = {
        preview_width = 0.55,
      },
      width = 0.95,
      height = 0.8,
    },
    mappings = {
      n = require "mappings.telescope.git_branches_actions",
    },
  }, opts or {})

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require("telescope.config").values
  local utils = require "telescope.utils"

  local results, err = display.list_branches(opts.cwd, {
    pattern = opts.pattern,
    show_remote_tracking_branches = opts.show_remote_tracking_branches,
  })
  if err then
    utils.notify("pretty_git_branch_picker", { msg = err, level = "ERROR" })
    return
  end
  if #results == 0 then
    return
  end

  local make_display = display.branch_displayer(display.branch_widths(results))

  pickers
    .new(opts, {
      prompt_title = "Git Branches",
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          entry.value = entry.name
          entry.ordinal = entry.name
          entry.display = make_display
          return make_entry.set_default_entry_mt(entry, opts)
        end,
      },
      previewer = branch_log_previewer(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        map("n", "?", function()
          require("mappings.telescope.git_branches_actions")["?"]()
        end)
        return true
      end,
    })
    :find()
end

return pretty_git_branch_picker
