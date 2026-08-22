-- Review a branch's history: pick a branch, then N commits, open their merged
-- tree diff in the existing MiniDiff review.

local display = require "configs.git_display"
local git = require "configs.gitutils"
local notify = require "configs.notify"
local pretty_date = require "utils.pretty_date"
local review = require "configs.minidiff_review"

local M = {}

local COMMIT_LIMIT = 300
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
local TITLE = "MiniDiff history"

---@param cwd string
---@param args string[]
---@return string|nil, string|nil
local function git_run(cwd, args)
  return git.run(args, cwd)
end

---@param cwd string
---@param ref_field string
---@return table
local function parent_diff_previewer(cwd, ref_field)
  local previewers = require "telescope.previewers"
  local putils = require "telescope.previewers.utils"

  return previewers.new_buffer_previewer {
    title = "Diff to parent",
    get_buffer_by_name = function(_, entry)
      return entry[ref_field] or entry.value
    end,
    define_preview = function(self, entry)
      local ref = entry[ref_field] or entry.value
      putils.job_maker(
        {
          "git",
          "-C",
          cwd,
          "--no-pager",
          "show",
          "--stat",
          "-p",
          "--format=medium",
          ref,
        },
        self.state.bufnr,
        {
          value = ref,
          bufname = self.state.bufname,
          callback = function(bufnr)
            if vim.api.nvim_buf_is_valid(bufnr) then
              putils.highlighter(bufnr, "diff", {})
            end
          end,
        }
      )
    end,
  }
end

---@class minidiff_history.Commit
---@field value string
---@field short string
---@field author string
---@field subject string
---@field display_subject string
---@field ts integer
---@field date string

---@param cwd string
---@param branch string
---@return minidiff_history.Commit[]
---@return string|nil err
local function list_commits(cwd, branch)
  local out, err = git_run(cwd, {
    "log",
    "--format=%H%x00%h%x00%an%x00%ct%x00%s",
    "-n",
    tostring(COMMIT_LIMIT),
    branch,
  })
  if not out then
    return {}, err or "git log failed"
  end

  local now = os.time()
  local commits = {}
  for line in vim.gsplit(out, "\n", { trimempty = true }) do
    local fields = vim.split(line, "\0", { plain = true })
    local hash = fields[1]
    if hash and hash ~= "" then
      local ts = tonumber(fields[4]) or 0
      commits[#commits + 1] = {
        value = hash,
        short = fields[2] or hash:sub(1, 7),
        author = display.shorten_author(fields[3] or ""),
        subject = fields[5] or "",
        display_subject = display.truncate_subject(fields[5] or ""),
        ts = ts,
        date = pretty_date(ts, now),
      }
    end
  end
  return commits, nil
end

---@param commits minidiff_history.Commit[]
---@return fun(entry: minidiff_history.Commit): table
local function commit_displayer(commits)
  local strings = require "plenary.strings"
  local entry_display = require "telescope.pickers.entry_display"
  local widths = { short = 0, author = 0, date = 0 }
  for _, commit in ipairs(commits) do
    for key, value in pairs(widths) do
      widths[key] = math.max(value, strings.strdisplaywidth(commit[key] or ""))
    end
  end
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = widths.short },
      { width = widths.author },
      { width = widths.date },
      { remaining = true },
    },
  }
  return function(entry)
    return displayer {
      { entry.short, "TelescopeResultsIdentifier" },
      { entry.author, "TelescopeResultsComment" },
      { entry.date, "TelescopeResultsComment" },
      { entry.display_subject, "TelescopeResultsNormal" },
    }
  end
end

---@param picker table
---@return minidiff_history.Commit[]
local function selected_commits(picker)
  local multi = picker:get_multi_selection()
  if #multi > 0 then
    return multi
  end
  local current = require("telescope.actions.state").get_selected_entry()
  if current and current.value then
    return { current }
  end
  return {}
end

---@param cwd string
---@param branch string
---@param commits minidiff_history.Commit[]
local function open_merged_review(cwd, branch, commits)
  if #commits == 0 then
    notify.send(TITLE, "No commits selected", vim.log.levels.WARN)
    return
  end

  table.sort(commits, function(a, b)
    if a.ts == b.ts then
      return a.value < b.value
    end
    return a.ts < b.ts
  end)

  local oldest = commits[1]
  local newest = commits[#commits]
  local parent_out = git_run(cwd, { "rev-parse", "--short", oldest.value .. "^" })
  local old_ref = parent_out and vim.trim(parent_out) or EMPTY_TREE
  local new_ref = newest.short

  notify.send(
    TITLE,
    string.format("Reviewing %d selected commit%s on %s as %s → %s", #commits, #commits == 1 and "" or "s", branch, old_ref, new_ref),
    vim.log.levels.INFO
  )
  review.start(old_ref, new_ref, cwd)
end

---@param cwd string
---@param branch string
local function pick_commits(cwd, branch)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  local commits, err = list_commits(cwd, branch)
  if err then
    notify.send(TITLE, err, vim.log.levels.ERROR)
    return
  end
  if #commits == 0 then
    notify.send(TITLE, "No commits on " .. branch, vim.log.levels.WARN)
    return
  end

  local make_display = commit_displayer(commits)

  notify.replace("minidiff.history.help", TITLE, "Press <Space> to add/remove a commit. Press <CR> to review the merged diff.", vim.log.levels.INFO)

  pickers
    .new({
      cwd = cwd,
      initial_mode = "normal",
      layout_config = {
        horizontal = { preview_width = 0.5 },
        width = 0.9,
        height = 0.8,
      },
    }, {
      prompt_title = "Commits on " .. branch,
      finder = finders.new_table {
        results = commits,
        entry_maker = function(item)
          item.ordinal = item.short .. " " .. item.subject
          item.display = make_display
          return item
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = parent_diff_previewer(cwd, "value"),
      attach_mappings = function(prompt_bufnr, map)
        local function toggle_commit()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local entry = action_state.get_selected_entry()
          if not entry or not entry.value then
            return
          end
          local was = false
          for _, selected in ipairs(picker:get_multi_selection()) do
            if selected.value == entry.value then
              was = true
              break
            end
          end
          actions.toggle_selection(prompt_bufnr)
          local n = #picker:get_multi_selection()
          notify.replace(
            "minidiff.history.selection",
            TITLE,
            string.format("%s %s — %d selected. <Space> toggle, <CR> review merged diff.", was and "Removed" or "Added", entry.short, n),
            vim.log.levels.INFO
          )
        end

        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local chosen = selected_commits(picker)
          actions.close(prompt_bufnr)
          open_merged_review(cwd, branch, chosen)
        end)
        map("n", "<Space>", toggle_commit)
        map("i", "<C-Space>", toggle_commit)
        return true
      end,
    })
    :find()
end

---@param cwd string
local function pick_branch(cwd)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"
  local conf = require("telescope.config").values

  local results, err = display.list_branches(cwd)
  if err then
    notify.send(TITLE, err, vim.log.levels.ERROR)
    return
  end
  if #results == 0 then
    notify.send(TITLE, "No branches found", vim.log.levels.WARN)
    return
  end

  local make_display = display.branch_displayer(display.branch_widths(results))

  notify.replace("minidiff.history.help", TITLE, "Select a branch. Preview is the tip commit's diff to its parent.", vim.log.levels.INFO)

  pickers
    .new({
      cwd = cwd,
      initial_mode = "normal",
      layout_config = {
        horizontal = { preview_width = 0.5 },
        width = 0.9,
        height = 0.8,
      },
    }, {
      prompt_title = "History branch",
      finder = finders.new_table {
        results = results,
        entry_maker = function(item)
          item.value = item.name
          item.ordinal = item.name
          item.display = make_display
          return make_entry.set_default_entry_mt(item, { cwd = cwd })
        end,
      },
      sorter = conf.file_sorter {},
      previewer = parent_diff_previewer(cwd, "value"),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection and selection.value then
            vim.schedule(function()
              pick_commits(cwd, selection.value)
            end)
          end
        end)
        return true
      end,
    })
    :find()
end

function M.open()
  local cwd, err = git.root(vim.fn.expand "%:p:h")
  if not cwd then
    notify.send(TITLE, err or "Not a git repository", vim.log.levels.ERROR)
    return
  end
  pick_branch(cwd)
end

function M.setup()
  vim.api.nvim_create_user_command("MiniDiffHistory", function()
    M.open()
  end, { desc = "Review merged diffs of commits from a branch history" })
end

return M
