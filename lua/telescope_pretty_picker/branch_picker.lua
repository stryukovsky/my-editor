-- Custom git-branch picker (does not replace telescope.builtin.git_branches).
-- List rows: display. Preview: preview.branch_log (or opts.previewer).

local display = require "telescope_pretty_picker.display"
local git = require "configs.gitutils"
local git_preview = require "telescope_pretty_picker.preview"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local commons = require "telescope_pretty_picker.commons"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local tell = commons.notifier "Git branches"

local HINTS = {
  { "<cr>", "switch to this picked branch" },
  { "m", "merge this picked branch into current git branch" },
  { "d", "delete branch" },
  { "r", "rebase current git branch on top of this picked branch" },
  { "y", "yank branch name" },
  { "?", "toggle this help off" },
}

---@type integer|nil
local help_win

local function close_help()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    vim.api.nvim_win_close(help_win, true)
  end
  help_win = nil
end

-- Overlay only — do not enter the float, or Telescope closes the picker.
local function help()
  if help_win and vim.api.nvim_win_is_valid(help_win) then
    close_help()
    return
  end

  local key_width = 0
  for _, row in ipairs(HINTS) do
    key_width = math.max(key_width, vim.fn.strdisplaywidth(row[1]))
  end

  local lines = {}
  for _, row in ipairs(HINTS) do
    local pad = string.rep(" ", key_width - vim.fn.strdisplaywidth(row[1]))
    lines[#lines + 1] = string.format(" %s%s  %s ", row[1], pad, row[2])
  end

  local width = 16
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].modifiable = false

  local height = #lines
  help_win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Git branches ",
    title_pos = "center",
    zindex = 200,
    focusable = false,
    noautocmd = true,
  })

  local ns = vim.api.nvim_create_namespace "telescope_pretty_picker_branch_help"
  for i, row in ipairs(HINTS) do
    pcall(
      vim.hl.range,
      buf,
      ns,
      "TelescopeResultsIdentifier",
      { i - 1, 1 },
      { i - 1, 1 + #row[1] }
    )
  end

  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
    buffer = vim.api.nvim_get_current_buf(),
    once = true,
    callback = close_help,
  })
end

local function notify_canceled()
  tell "action canceled"
end

local function warn_no_selection()
  tell("Nothing currently selected", vim.log.levels.WARN)
end

---Telescope `actions.git_delete_branch`, with `vim.fn.confirm`.
---@param prompt_bufnr integer
local function git_delete_branch(prompt_bufnr)
  if
    not commons.confirmed "Do you really want to delete the selected branches?"
  then
    notify_canceled()
    return
  end

  local picker = action_state.get_current_picker(prompt_bufnr)
  picker:delete_selection(function(selection)
    local branch = selection.value
    local _, err = git.run({ "branch", "-D", branch }, picker.cwd)
    local ok = err == nil
    -- After the picker refreshes, so the toast is not opened during the redraw.
    vim.schedule(function()
      if ok then
        tell(string.format("Deleted branch: %s", branch))
      else
        tell(
          string.format(
            "Error when deleting branch: %s. Git returned: '%s'",
            branch,
            err
          ),
          vim.log.levels.ERROR
        )
      end
    end)
    return ok
  end)
end

-- Compare the selected local branch with its configured remote-tracking ref.
local function merge_confirmation(selection, cwd)
  local question =
    string.format("Do you really want to merge branch %s?", selection.value)
  local ref = selection.refname or ""
  if not vim.startswith(ref, "refs/heads/") then
    return question
  end

  local output, err =
    git.run({ "for-each-ref", "--format=%(upstream)", ref }, cwd)
  if not output then
    return nil, err
  end
  local upstream = vim.trim(output)
  if not vim.startswith(upstream, "refs/remotes/") then
    return question
  end

  local counts
  counts, err = git.run(
    { "rev-list", "--left-right", "--count", ref .. "..." .. upstream },
    cwd
  )
  if not counts then
    return nil, err
  end
  local ahead, behind = counts:match "^(%d+)%s+(%d+)"
  ahead, behind = tonumber(ahead), tonumber(behind)
  if not ahead or not behind then
    return nil, "Cannot compare branch with " .. upstream
  end
  if ahead == 0 and behind == 0 then
    return question
  end

  local remote_name = upstream:sub(#"refs/remotes/" + 1)
  local warning = string.format(
    "%s has %d new commits missing from %s.",
    remote_name,
    behind,
    selection.value
  )
  if ahead > 0 then
    warning = warning
      .. string.format(
        "\n%s has %d commits missing from %s.",
        selection.value,
        ahead,
        remote_name
      )
  end
  return warning
    .. "\nMerge local branch "
    .. selection.value
    .. " into the current branch anyway?"
end

---Telescope `make_git_branch_action` for merge/rebase, with `vim.fn.confirm`.
---@param opts { confirmation_question: string|function, success_message: string, error_message: string, command: fun(branch_name: string): string[] }
---@return fun(prompt_bufnr: integer)
local function make_git_branch_action(opts)
  return function(prompt_bufnr)
    local cwd = action_state.get_current_picker(prompt_bufnr).cwd
    local selection = action_state.get_selected_entry()
    if selection == nil then
      warn_no_selection()
      return
    end

    local question, check_err
    if type(opts.confirmation_question) == "function" then
      question, check_err = opts.confirmation_question(selection, cwd)
    else
      question = string.format(opts.confirmation_question, selection.value)
    end
    if not question then
      tell(
        check_err or "Cannot check branch tracking status",
        vim.log.levels.ERROR
      )
      return
    end
    if not commons.confirmed(question) then
      notify_canceled()
      return
    end

    actions.close(prompt_bufnr)
    local _, err = git.run(opts.command(selection.value), cwd)
    if not err then
      tell(string.format(opts.success_message, selection.value))
    else
      tell(
        string.format(opts.error_message, selection.value, err),
        vim.log.levels.ERROR
      )
    end
  end
end

local git_merge_branch = make_git_branch_action {
  confirmation_question = merge_confirmation,
  success_message = "Merged branch: %s",
  error_message = "Error when merging branch: %s. Git returned: '%s'",
  command = function(branch_name)
    return { "merge", branch_name }
  end,
}

local git_rebase_branch = make_git_branch_action {
  confirmation_question = "Do you really want to rebase branch %s?",
  success_message = "Rebased branch: %s",
  error_message = "Error when rebasing branch: %s. Git returned: '%s'",
  command = function(branch_name)
    return { "rebase", branch_name }
  end,
}

---Local branch, or `git switch` onto a remote-only ref (strip `refs/remotes/<remote>/`).
---@param prompt_bufnr integer
local function git_switch_branch(prompt_bufnr)
  local cwd = action_state.get_current_picker(prompt_bufnr).cwd
  local selection = action_state.get_selected_entry()
  if selection == nil then
    warn_no_selection()
    return
  end

  actions.close(prompt_bufnr)
  local branch = selection.value
  local refname = selection.refname
  if type(refname) == "string" and refname:match "^refs/remotes/%w+/" then
    branch = refname:gsub("^refs/remotes/%w+/", "")
  end

  local _, err = git.run({ "switch", branch }, cwd)
  if not err then
    tell(string.format("Switched to: '%s'", branch))
  else
    tell(
      string.format(
        "Error when switching to: %s. Git returned: '%s'",
        selection.value,
        err
      ),
      vim.log.levels.ERROR
    )
  end
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

  -- History/review pass attach_mappings / previewer; peel them off so they are
  -- not treated as Telescope picker opts.
  local custom_attach = opts.attach_mappings
  local custom_previewer = opts.previewer
  local prompt_title = opts.prompt_title or "Git Branches"
  local results_title = opts.results_title
  opts.attach_mappings = nil
  opts.previewer = nil
  opts.prompt_title = nil
  opts.results_title = nil

  local results, err = display.list_branches(cwd, {
    pattern = opts.pattern,
    show_remote_tracking_branches = opts.show_remote_tracking_branches,
  })
  if err then
    tell(err, vim.log.levels.ERROR)
    return
  end
  if #results == 0 then
    return
  end

  require "utils.ui_prevent_mess"()
  local make_display = display.branch_displayer(display.branch_widths(results))

  pickers
    .new(opts, {
      prompt_title = prompt_title,
      results_title = results_title,
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          entry.value = entry.name
          entry.ordinal = entry.name
          entry.display = make_display
          return make_entry.set_default_entry_mt(entry, opts)
        end,
      },
      -- Default graph log; MiniDiff history overrides with commit_diff.
      previewer = custom_previewer or git_preview.branch_log { cwd = cwd },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        if custom_attach then
          return custom_attach(prompt_bufnr, map)
        end
        -- override mappings of telescope only this way :(
        map("n", "<cr>", wrap_telescope_action(git_switch_branch))
        map("n", "?", help)
        map("n", "d", wrap_telescope_action(git_delete_branch))
        map("n", "m", wrap_telescope_action(git_merge_branch))
        -- `y` = yank branch name (mappings.telescope.defaults)
        map("n", "r", wrap_telescope_action(git_rebase_branch))
        return true
      end,
    })
    :find()
end

return pretty_git_branch_picker
