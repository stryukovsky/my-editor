-- Custom git-branch picker (does not replace telescope.builtin.git_branches).
-- List rows: display. Preview: preview.branch_log (or opts.previewer).

local display = require "telescope_pretty_picker.display"
local git = require "moonshine.git"
local git_preview = require "telescope_pretty_picker.preview"
local commons = require "telescope_pretty_picker.commons"
local menu = require "telescope_pretty_picker.action_menu"
local scheduler = require "moonshine.git.scheduler"

local tell = commons.notifier "Git branches"

local PROMPT_HINTS =
  "Enter actions, d delete, m merge, r rename, R rebase, y yank"

local function notify_canceled()
  tell "action canceled"
end

local function warn_no_selection()
  tell("Nothing currently selected", vim.log.levels.WARN)
end

---Telescope `actions.git_delete_branch`, with `vim.fn.confirm`.
---@param context table
local function git_delete_branch(context)
  if
    not commons.confirmed "Do you really want to delete the selected branches?"
  then
    notify_canceled()
    return
  end

  local function delete(selection)
    local branch = selection.value
    local _, err = git.run({ "branch", "-D", branch }, context.cwd)
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
  end
  if context.prompt_bufnr then
    context.picker:delete_selection(delete)
  else
    for _, entry in ipairs(context.entries) do
      delete(entry)
    end
    context.reopen()
  end
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
---@return fun(context: table)
local function make_git_branch_action(opts)
  return function(context)
    local cwd = context.cwd
    local selection = context.selection
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

    context.close()
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

local function git_rename_branch(context, lease)
  local selection = context.selection
  if not selection then
    warn_no_selection()
    return
  end
  if not vim.startswith(selection.refname or "", "refs/heads/") then
    tell("Only local branches can be renamed", vim.log.levels.WARN)
    return
  end
  local cwd = context.cwd
  local branch = selection.value
  context.close()
  return lease:schedule(function()
    return lease:input(
      { prompt = "Rename branch: ", default = branch, cwd = cwd },
      function(value)
        if not value or vim.trim(value) == "" or value == branch then
          return
        end
        local _, err = git.run({ "branch", "-m", branch, value }, cwd)
        if err then
          tell(err, vim.log.levels.ERROR)
        else
          tell(string.format("Renamed branch: %s → %s", branch, value))
        end
      end
    )
  end)
end

---Switch local branches, or create a tracking branch from the selected remote.
---@param context table
local function git_switch_branch(context)
  local cwd = context.cwd
  local selection = context.selection
  if selection == nil then
    warn_no_selection()
    return
  end

  context.close()
  local branch = selection.value
  local refname = selection.refname
  local args = { "switch", branch }
  if type(refname) == "string" and refname:match "^refs/remotes/[^/]+/" then
    branch = refname:gsub("^refs/remotes/[^/]+/", "")
    local local_ref = git.run(
      { "show-ref", "--verify", "--quiet", "refs/heads/" .. branch },
      cwd
    )
    args = local_ref and { "switch", branch }
      or { "switch", "--track", "-c", branch, refname }
  end

  local _, err = git.run(args, cwd)
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
---@param restore_selection? fun(picker: table) Internal one-shot restoration.
local function pretty_git_branch_picker(opts, restore_selection)
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
  local reopen_opts = vim.tbl_extend("force", {}, opts)

  local custom_attach = opts.attach_mappings
  local custom_previewer = opts.previewer
  if custom_previewer == nil then
    custom_previewer = git_preview.branch_log { cwd = cwd }
  end
  local prompt_title = opts.prompt_title
    or (custom_attach and "Git Branches" or PROMPT_HINTS)
  local results_title = opts.results_title
    or (not custom_attach and "Git Branches" or nil)
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

  require "moonshine.utils.ui_prevent_mess"()
  local make_display = display.branch_displayer(display.branch_widths(results))

  local picker = pickers.new(opts, {
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
    previewer = custom_previewer,
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, telescope_map)
      if custom_attach then
        return custom_attach(prompt_bufnr, telescope_map)
      end
      return menu.attach(
        prompt_bufnr,
        reopen_opts,
        pretty_git_branch_picker,
        tell,
        {
          {
            "Switch branch",
            scheduler.wrap("Switch branch", git_switch_branch),
          },
          {
            "Delete branch",
            scheduler.wrap("Delete branch", git_delete_branch),
            keys = { "d" },
          },
          {
            "Merge branch",
            scheduler.wrap("Merge branch", git_merge_branch),
            keys = { "m" },
          },
          {
            "Rename branch",
            scheduler.wrap("Rename branch", git_rename_branch),
            keys = { "r" },
          },
          {
            "Rebase onto branch",
            scheduler.wrap("Rebase onto branch", git_rebase_branch),
            keys = { "R" },
          },
          { "Yank branch name", menu.yank, keys = { "y" } },
        }
      )
    end,
  })
  if restore_selection then
    picker:register_completion_callback(restore_selection)
  end
  picker:find()
end

return pretty_git_branch_picker
