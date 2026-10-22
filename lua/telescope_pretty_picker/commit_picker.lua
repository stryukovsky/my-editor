-- Custom git-commit picker (does not replace telescope.builtin.git_commits).
-- List rows: display. Preview: preview.commit_diff (or opts.previewer).

local display = require "telescope_pretty_picker.display"
local git = require "configs.gitutils"
local git_preview = require "telescope_pretty_picker.preview"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local commons = require "telescope_pretty_picker.commons"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local COMMIT_LIMIT = 1000
local tell = commons.notifier "Git commits"

---@param prompt_bufnr integer
---@return table|nil selection
---@return string|nil cwd
local function selected(prompt_bufnr)
  local selection = action_state.get_selected_entry()
  if selection == nil then
    tell("Nothing currently selected", vim.log.levels.WARN)
    return nil, nil
  end
  return selection, action_state.get_current_picker(prompt_bufnr).cwd
end

---@param prompt_bufnr integer
local function git_checkout(prompt_bufnr)
  local selection, cwd = selected(prompt_bufnr)
  if not selection then
    return
  end
  actions.close(prompt_bufnr)
  local _, err = git.run({ "checkout", selection.value }, cwd)
  if not err then
    tell(string.format("Checked out: %s", selection.value))
    vim.cmd "checktime"
  else
    tell(
      string.format(
        "Error when checking out: %s. Git returned: '%s'",
        selection.value,
        err
      ),
      vim.log.levels.ERROR
    )
  end
end

---@param mode "--mixed"|"--soft"|"--hard"
---@return fun(prompt_bufnr: integer)
local function git_reset(mode)
  local label = mode:sub(3)
  return function(prompt_bufnr)
    local selection, cwd = selected(prompt_bufnr)
    if not selection then
      return
    end
    local question =
      string.format("Do you really want to %s reset to %s?", label, selection.value)
    if not commons.confirmed(question) then
      tell "action canceled"
      return
    end
    actions.close(prompt_bufnr)
    local _, err = git.run({ "reset", mode, selection.value }, cwd)
    if not err then
      tell(string.format("Reset to: '%s'", selection.value))
    else
      tell(
        string.format(
          "Error when resetting to: %s. Git returned: '%s'",
          selection.value,
          err
        ),
        vim.log.levels.ERROR
      )
    end
  end
end

---@param opts? table
local function pretty_git_commit_picker(opts)
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
  }, opts or {})

  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require("telescope.config").values

  local cwd, root_err = git.root(opts.cwd)
  if not cwd then
    tell(root_err or "Not a git repository", vim.log.levels.ERROR)
    return
  end
  opts.cwd = cwd

  local custom_attach = opts.attach_mappings
  local custom_previewer = opts.previewer
  local prompt_title = opts.prompt_title or (opts.ref and ("Git Commits on " .. opts.ref) or "Git Commits")
  local results_title = opts.results_title
  local ref = opts.ref
  local limit = opts.limit or COMMIT_LIMIT
  opts.attach_mappings = nil
  opts.previewer = nil
  opts.prompt_title = nil
  opts.results_title = nil
  opts.ref = nil
  opts.limit = nil

  local commits, err = display.list_commits(cwd, {
    ref = ref,
    limit = limit,
  })
  if err then
    tell(err, vim.log.levels.ERROR)
    return
  end
  if #commits == 0 then
    return
  end

  require("utils.ui_prevent_mess")()
  local make_display = display.commit_displayer(display.commit_widths(commits))

  pickers
    .new(opts, {
      prompt_title = prompt_title,
      results_title = results_title,
      finder = finders.new_table {
        results = commits,
        entry_maker = function(entry)
          entry.ordinal = entry.short .. " " .. entry.subject
          entry.display = make_display
          return make_entry.set_default_entry_mt(entry, opts)
        end,
      },
      -- Same async git_preview as <A-c>; MiniDiff history reuses this picker.
      previewer = custom_previewer or git_preview.commit_diff { cwd = cwd },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        if custom_attach then
          return custom_attach(prompt_bufnr, map)
        end
        -- override mappings of telescope only this way :(
        map("n", "<cr>", wrap_telescope_action(git_checkout))
        map("n", "m", wrap_telescope_action(git_reset "--mixed"))
        map("n", "s", wrap_telescope_action(git_reset "--soft"))
        map("n", "h", wrap_telescope_action(git_reset "--hard"))
        return true
      end,
    })
    :find()
end

return pretty_git_commit_picker
