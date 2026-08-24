-- Review a branch's history: pick a branch, then N commits, open their merged
-- tree diff in the existing MiniDiff review.

local display = require "configs.git_display"
local git = require "configs.gitutils"
local notify = require "configs.notify"
local review = require "configs.minidiff_review"

local M = {}

local COMMIT_LIMIT = 300
local EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
local TITLE = "MiniDiff history"
local COMMIT_HELP = "<Space> toggle + next · <CR> review merged diff"

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

---@param picker table
---@return git_display.Commit[]
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
---@param commits git_display.Commit[]
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

  local commits, err = display.list_commits(cwd, { ref = branch, limit = COMMIT_LIMIT })
  if err then
    notify.send(TITLE, err, vim.log.levels.ERROR)
    return
  end
  if #commits == 0 then
    notify.send(TITLE, "No commits on " .. branch, vim.log.levels.WARN)
    return
  end

  local make_display = display.commit_displayer(display.commit_widths(commits))

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
      results_title = COMMIT_HELP,
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
          actions.move_selection_next(prompt_bufnr)
          local n = #picker:get_multi_selection()
          notify.replace(
            "minidiff.history.selection",
            TITLE,
            string.format("%s %s — %d selected. <Space> toggle and go next, <CR> review merged diff.", was and "Removed" or "Added", entry.short, n),
            vim.log.levels.INFO
          )
        end

        actions.select_default:replace(function()
          local picker = action_state.get_current_picker(prompt_bufnr)
          local chosen = selected_commits(picker)
          actions.close(prompt_bufnr)
          open_merged_review(cwd, branch, chosen)
        end)
        map("n", "<leader>", toggle_commit, { nowait = true })
        map("n", "<leader><leader>", function()
          toggle_commit()
          vim.schedule(function()
            toggle_commit()
          end)
        end)
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
      prompt_title = "select a branch where to see commits changes",
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
