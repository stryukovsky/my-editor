-- MiniDiff history: pick a branch, then N commits, open their merged tree diff.
-- Reuses pretty_git_* pickers (list rows + git_preview). Only mappings differ.

local git = require "configs.gitutils"
local git_preview = require "configs.git_preview"
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
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  -- Pretty commit list + git_preview.commit_diff; <CR> starts a merged review.
  require("configs.pretty_git_commit_picker") {
    cwd = cwd,
    ref = branch,
    limit = COMMIT_LIMIT,
    prompt_title = "Commits on " .. branch,
    results_title = COMMIT_HELP,
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
  }
end

---@param cwd string
local function pick_branch(cwd)
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  -- Pretty branch UI, but preview the tip patch (not the graph log) and
  -- <CR> opens the commit picker instead of switching branch.
  require("configs.pretty_git_branch_picker") {
    cwd = cwd,
    prompt_title = "select a branch where to see commits changes",
    previewer = git_preview.commit_diff { cwd = cwd },
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
  }
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
