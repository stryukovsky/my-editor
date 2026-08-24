-- Custom git-commit picker (does not replace telescope.builtin.git_commits).

local display = require "configs.git_display"
local git = require "configs.gitutils"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local COMMIT_LIMIT = 1000

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
  local previewers = require "telescope.previewers"
  local actions = require "telescope.actions"
  local utils = require "telescope.utils"

  local cwd, root_err = git.root(opts.cwd)
  if not cwd then
    utils.notify("pretty_git_commit_picker", { msg = root_err or "Not a git repository", level = "ERROR" })
    return
  end
  opts.cwd = cwd

  local commits, err = display.list_commits(cwd, {
    ref = opts.ref,
    limit = opts.limit or COMMIT_LIMIT,
  })
  if err then
    utils.notify("pretty_git_commit_picker", { msg = err, level = "ERROR" })
    return
  end
  if #commits == 0 then
    return
  end

  local make_display = display.commit_displayer(display.commit_widths(commits))

  pickers
    .new(opts, {
      prompt_title = opts.ref and ("Git Commits on " .. opts.ref) or "Git Commits",
      finder = finders.new_table {
        results = commits,
        entry_maker = function(entry)
          entry.ordinal = entry.short .. " " .. entry.subject
          entry.display = make_display
          return make_entry.set_default_entry_mt(entry, opts)
        end,
      },
      previewer = {
        previewers.git_commit_diff_to_parent.new(opts),
        previewers.git_commit_diff_to_head.new(opts),
        previewers.git_commit_diff_as_was.new(opts),
        previewers.git_commit_message.new(opts),
      },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        -- override mappings of telescope only this way :(
        map("n", "<cr>", wrap_telescope_action(actions.git_checkout))
        map("n", "m", wrap_telescope_action(actions.git_reset_mixed))
        map("n", "s", wrap_telescope_action(actions.git_reset_soft))
        map("n", "h", wrap_telescope_action(actions.git_reset_hard))
        return true
      end,
    })
    :find()
end

return pretty_git_commit_picker
