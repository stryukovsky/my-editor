-- Custom git-commit picker (does not replace telescope.builtin.git_commits).
-- List rows: display. Preview: preview.commit_diff (or opts.previewer).

local display = require "telescope_pretty_picker.display"
local git = require "moonshine.git"
local git_preview = require "telescope_pretty_picker.preview"
local commons = require "telescope_pretty_picker.commons"
local menu = require "telescope_pretty_picker.action_menu"
local scheduler = require "moonshine.git.scheduler"

local COMMIT_LIMIT = 1000
local PROMPT_HINTS =
  "Enter actions, v view files, a/r rename, x/u undo, s undo+stash (HEAD), y yank"
local tell = commons.notifier "Git commits"

---@param context table
---@return table|nil selection
---@return string|nil cwd
local function selected(context)
  local selection = context.selection
  if selection == nil then
    tell("Nothing currently selected", vim.log.levels.WARN)
    return nil, nil
  end
  return selection, context.cwd
end

---@param context table
local function view_files(context)
  local selection, cwd = selected(context)
  if not selection then
    return
  end
  local paths, err = git.run({
    "diff-tree", "--root", "-m", "-r", "--no-commit-id",
    "--name-only", "--no-renames", "-z", selection.value, "--",
  }, cwd, { text = false })
  if not paths then
    tell(err, vim.log.levels.ERROR)
  else
    local files, seen = {}, {}
    for path in vim.gsplit(paths, "\0", { plain = true, trimempty = true }) do
      local filename = cwd .. "/" .. path
      if not seen[filename] and vim.fn.filereadable(filename) == 1 then
        seen[filename] = true
        files[#files + 1] = filename
      end
    end
    if #files > 0 then
      context.close()
      local trouble = require "trouble"
      trouble.close "git_commit_files"
      trouble.open { mode = "git_commit_files", commit_files = files, max_items = #files }
      return
    end
    tell "No affected files in the current worktree"
  end
  if not context.prompt_bufnr then
    context.reopen()
  end
end

---@param context table
local function git_checkout(context)
  local selection, cwd = selected(context)
  if not selection then
    return
  end
  local head, head_err = git.run({ "rev-parse", "HEAD" }, cwd)
  if not head then
    tell(head_err, vim.log.levels.ERROR)
    return
  end
  if vim.trim(head) == selection.value then
    tell "Already at this commit"
    return
  end
  context.close()
  local _, err = git.run({ "switch", "--detach", selection.value }, cwd)
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

-- These actions change only HEAD; selecting an older row must never discard
-- the commits above it.
local function selected_head(context)
  local selection, cwd = selected(context)
  if not selection then
    return
  end
  local head, err = git.run({ "rev-parse", "HEAD" }, cwd)
  if not head then
    tell(err, vim.log.levels.ERROR)
    return
  end
  head = vim.trim(head)
  if selection.value ~= head then
    tell(
      "This action is only available for the latest commit (HEAD)",
      vim.log.levels.WARN
    )
    return
  end
  return selection, cwd, head
end

local function git_rename(context, lease)
  local selection, cwd, head = selected_head(context)
  if not selection then
    return
  end
  local message, err = git.run({ "show", "-s", "--format=%B", head }, cwd)
  if not message then
    tell(err, vim.log.levels.ERROR)
    return
  end
  local subject, body = message:match "^([^\n]*)(.*)$"
  context.close()
  return lease:schedule(function()
    return lease:input({
      prompt = "Rename commit: ",
      default = subject,
      filetype = "gitcommit",
      cwd = cwd,
    }, function(value)
      if not value or vim.trim(value) == "" then
        return
      end
      local current, check_err = git.run({ "rev-parse", "HEAD" }, cwd)
      if not current or vim.trim(current) ~= head then
        tell(
          check_err or "HEAD changed while renaming; action canceled",
          vim.log.levels.WARN
        )
        return
      end
      -- --only keeps already staged changes out of this message-only amend.
      local _, amend_err =
        git.run({ "commit", "--amend", "--only", "-m", value .. body }, cwd)
      if amend_err then
        tell(amend_err, vim.log.levels.ERROR)
      else
        tell("Renamed commit: " .. value)
      end
    end)
  end)
end

local function git_undo(stash)
  return function(context)
    local selection, cwd, head = selected_head(context)
    if not selection then
      return
    end
    local parent, err = git.run({ "rev-parse", "--verify", head .. "^" }, cwd)
    if not parent then
      tell(
        "Cannot undo the initial commit with a soft reset",
        vim.log.levels.WARN
      )
      return
    end
    if stash then
      local status
      status, err =
        git.run({ "status", "--porcelain", "--untracked-files=no" }, cwd)
      if not status then
        tell(err, vim.log.levels.ERROR)
        return
      end
      if status ~= "" then
        tell(
          "Commit or stash existing tracked changes before undoing and stashing HEAD",
          vim.log.levels.WARN
        )
        return
      end
    end
    local question = stash
        and string.format(
          "Undo HEAD %s and stash its changes?",
          selection.subject
        )
      or string.format(
        "Undo HEAD %s with a soft reset (keep changes staged)?",
        selection.subject
      )
    if not commons.confirmed(question) then
      tell "action canceled"
      return
    end
    context.close()
    local _, reset_err = git.run({ "reset", "--soft", vim.trim(parent) }, cwd)
    if reset_err then
      tell(reset_err, vim.log.levels.ERROR)
      return
    end
    if stash then
      local _, stash_err = git.run(
        { "stash", "push", "-m", "Undo commit: " .. selection.subject },
        cwd
      )
      if stash_err then
        -- Restore the commit if stashing fails; do not leave an unnoticed undo.
        local _, restore_err = git.run({ "reset", "--soft", head }, cwd)
        tell(
          stash_err
            .. (
              restore_err and ("\nCould not restore HEAD: " .. restore_err)
              or "\nRestored HEAD"
            ),
          vim.log.levels.ERROR
        )
        return
      end
      vim.cmd "checktime"
    end
    tell(
      stash and "Undid HEAD and stashed its changes"
        or "Undid HEAD; changes remain staged"
    )
  end
end

---@param opts? table
---@param restore_selection? fun(picker: table) Internal one-shot restoration.
local function pretty_git_commit_picker(opts, restore_selection)
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

  local reopen_opts = vim.tbl_extend("force", {}, opts)

  local custom_attach = opts.attach_mappings
  local custom_previewer = opts.previewer
  if custom_previewer == nil then
    custom_previewer = git_preview.commit_diff { cwd = cwd }
  end
  local commit_title = opts.ref and ("Git Commits on " .. opts.ref)
    or "Git Commits"
  local prompt_title = opts.prompt_title
    or (custom_attach and commit_title or PROMPT_HINTS)
  local results_title = opts.results_title
    or (not custom_attach and commit_title or nil)
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

  require "moonshine.utils.ui_prevent_mess"()
  local make_display = display.commit_displayer(display.commit_widths(commits))

  local picker = pickers.new(opts, {
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
    previewer = custom_previewer,
    sorter = conf.file_sorter(opts),
    attach_mappings = function(prompt_bufnr, telescope_map)
      if custom_attach then
        return custom_attach(prompt_bufnr, telescope_map)
      end
      return menu.attach(
        prompt_bufnr,
        reopen_opts,
        pretty_git_commit_picker,
        tell,
        {
          {
            "Checkout commit (detached HEAD)",
            scheduler.wrap("checkout", git_checkout),
          },
          { "View affected files (v)", view_files, keys = { "v" } },
          {
            "Rename HEAD commit",
            scheduler.wrap("amend", git_rename),
            keys = { "a", "r" },
          },
          {
            "Undo HEAD (keep changes staged)",
            scheduler.wrap("undo commit", git_undo(false)),
            keys = { "x", "u" },
          },
          {
            "Undo HEAD and stash changes",
            scheduler.wrap("undo and stash", git_undo(true)),
            keys = { "s" },
          },
          { "Yank commit SHA", menu.yank, keys = { "y" } },
        }
      )
    end,
  })
  if restore_selection then
    picker:register_completion_callback(restore_selection)
  end
  picker:find()
end

return pretty_git_commit_picker
