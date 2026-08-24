-- Custom git-branch picker (does not replace telescope.builtin.git_branches).
-- List rows: display. Preview: preview.branch_log (or opts.previewer).

local display = require "telescope_pretty_git.display"
local git = require "configs.gitutils"
local git_preview = require "telescope_pretty_git.preview"
local actions = require "telescope.actions"
local wrap_telescope_action = require "mappings.telescope_action_wrapper"

local HINTS = {
  { "<cr>", "switch to this picked branch" },
  { "m", "merge this picked branch into current git branch" },
  { "d", "delete branch" },
  { "r", "rebase current git branch on top of this picked branch" },
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

  local ns = vim.api.nvim_create_namespace "telescope_pretty_git_branch_help"
  for i, row in ipairs(HINTS) do
    pcall(vim.hl.range, buf, ns, "TelescopeResultsIdentifier", { i - 1, 1 }, { i - 1, 1 + #row[1] })
  end

  vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
    buffer = vim.api.nvim_get_current_buf(),
    once = true,
    callback = close_help,
  })
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
  local utils = require "telescope.utils"

  local cwd, root_err = git.root(opts.cwd)
  if not cwd then
    utils.notify("pretty_git_branch_picker", { msg = root_err or "Not a git repository", level = "ERROR" })
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
    utils.notify("pretty_git_branch_picker", { msg = err, level = "ERROR" })
    return
  end
  if #results == 0 then
    return
  end

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
        map("n", "<cr>", actions.git_switch_branch)
        map("n", "?", help)
        map("n", "d", wrap_telescope_action(actions.git_delete_branch))
        map("n", "m", wrap_telescope_action(actions.git_merge_branch))
        map("n", "r", wrap_telescope_action(actions.git_rebase_branch))
        return true
      end,
    })
    :find()
end

return pretty_git_branch_picker
