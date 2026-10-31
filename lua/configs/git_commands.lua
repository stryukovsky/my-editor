local git = require "configs.gitutils"
local notify = require "configs.notify"
local M = { busy = {} }
local queues = {}

local function root(state)
  if not state and vim.bo.filetype == "neo-tree" then
    state = require("neo-tree.sources.manager").get_state_for_window()
  end
  local cwd, err = git.root(state and state.path)
  if not cwd then
    notify.send("Git", err, vim.log.levels.ERROR)
  end
  return cwd
end

local function result_message(action, stdout, stderr)
  local output = vim.trim(stdout .. "\n" .. stderr)
  local lower = output:lower()
  if action.name == "push" and (lower:find "everything up%-to%-date" or lower:find("everything is up to date", 1, true)) then
    return "Everything is up to date"
  elseif action.name == "pull" and (lower:find("already up to date", 1, true) or lower:find "already up%-to%-date") then
    return "Already up to date"
  elseif action.name == "stash" and lower:find("no local changes", 1, true) then
    return "No local changes to stash"
  end
  if lower:find("conflict", 1, true) then
    return action.done .. "\n" .. output, vim.log.levels.WARN
  end
  return action.done
end

local function refresh(cwd)
  -- Failed commands may also change the index/worktree (e.g. merge conflicts).
  if package.loaded["neo-tree"] then
    local events = require "neo-tree.events"
    events.fire_event(events.GIT_EVENT)
  end
  vim.cmd "checktime"
  local fetch = package.loaded["configs.periodic-git-fetch"]
  if fetch then
    fetch.refresh_sync_state(cwd, true)
  end
end

local run
run = function(cwd, steps, action, enqueue)
  if M.busy[cwd] then
    if enqueue then
      queues[cwd] = queues[cwd] or {}
      queues[cwd][#queues[cwd] + 1] = { steps = steps, action = action }
    else
      notify.send("Git", "Another Git action is running", vim.log.levels.WARN)
    end
    return
  end
  local fetch = package.loaded["configs.periodic-git-fetch"]
  if fetch and fetch.fetch_pending then
    notify.send("Git", "Background fetch is running; try again shortly", vim.log.levels.WARN)
    return
  end
  M.busy[cwd] = true
  local key = "git.action:" .. cwd
  notify.replace(key, "Git", action.progress, nil, { timeout = false })
  local function finished(code, stderr, stdout)
    M.busy[cwd] = nil
    local message, level
    if code == 0 then
      message, level = result_message(action, stdout, stderr)
    else
      local output = vim.trim(stdout .. "\n" .. stderr)
      if action.name == "commit" and (output:find("nothing to commit", 1, true) or output:find("no changes added to commit", 1, true)) then
        message, level = "Nothing to commit", vim.log.levels.WARN
      else
        message = action.failed .. (output ~= "" and ("\n" .. output) or "")
        level = vim.log.levels.ERROR
      end
    end
    notify.replace(key, "Git", message, level, { timeout = 4000 })
    refresh(cwd)
    local queue = queues[cwd]
    local next_action = queue and table.remove(queue, 1)
    if queue and #queue == 0 then
      queues[cwd] = nil
    end
    if next_action then
      run(cwd, next_action.steps, next_action.action, true)
    end
  end
  local function step(index)
    local ok, err = pcall(git.job, {
      cwd = cwd,
      args = steps[index],
      on_exit = function(code, stderr, stdout)
        vim.schedule(function()
          if code == 0 and index < #steps then
            step(index + 1)
          else
            finished(code, stderr, stdout)
          end
        end)
      end,
    })
    if not ok then
      finished(-1, tostring(err), "")
    end
  end
  step(1)
end

local function action(name, progress, done, failed)
  return { name = name, progress = progress, done = done, failed = failed }
end

local function command(state, args, info)
  local cwd = root(state)
  if cwd then
    run(cwd, { args }, info)
  end
end

function M.pull(state)
  command(state, { "pull", "--rebase", "--autostash" }, action("pull", "Pulling…", "Pulled changes", "Pull failed"))
end

function M.push(state)
  command(state, { "-c", "push.autoSetupRemote=true", "push" }, action("push", "Pushing…", "Pushed successfully", "Push failed"))
end

function M.fetch(state)
  command(state, { "fetch" }, action("fetch", "Fetching…", "Fetched remote changes", "Fetch failed"))
end

function M.merge_continue(state)
  command(
    state,
    { "-c", "core.editor=true", "merge", "--continue" },
    action("merge", "Continuing merge…", "Merge completed", "Could not continue merge")
  )
end

function M.merge_abort(state)
  command(state, { "merge", "--abort" }, action("merge", "Aborting merge…", "Merge aborted", "Could not abort merge"))
end

function M.stash(state)
  command(state, { "stash", "push", "--include-untracked" }, action("stash", "Stashing changes…", "Changes stashed", "Stash failed"))
end

function M.stash_pop(state)
  command(state, { "stash", "pop" }, action("stash_pop", "Applying stash…", "Stash applied", "Could not apply stash"))
end

local function input_command(state, prompt, args, info, default)
  local cwd = root(state)
  if not cwd then
    return
  end
  vim.ui.input({ prompt = prompt, default = default }, function(value)
    if not value or vim.trim(value) == "" then
      return
    end
    local command_args = vim.list_extend(vim.deepcopy(args), { value })
    local details = vim.tbl_extend("force", info, { done = info.done .. value })
    run(cwd, { command_args }, details)
  end)
end

function M.branch_create(state)
  input_command(
    state,
    "New branch: ",
    { "switch", "-c" },
    action("branch", "Creating branch…", "Switched to new branch: ", "Could not create branch")
  )
end

function M.branch_rename(state)
  local cwd = root(state)
  if not cwd then
    return
  end
  local branch, err = git.run({ "symbolic-ref", "--quiet", "--short", "HEAD" }, cwd)
  if not branch then
    notify.send("Git", err, vim.log.levels.ERROR)
    return
  end
  input_command(
    { path = cwd },
    "Rename current branch: ",
    { "branch", "-m" },
    action("branch", "Renaming branch…", "Renamed branch to: ", "Could not rename branch"),
    vim.trim(branch)
  )
end

function M.commit(state)
  input_command(state, "Commit message: ", { "commit", "-m" }, action("commit", "Committing…", "Committed: ", "Commit failed"))
end

function M.checkpoint(state)
  local cwd = root(state)
  if not cwd then
    return
  end
  local status, err = git.run({ "status", "--porcelain" }, cwd)
  if not status then
    notify.send("Git", err, vim.log.levels.ERROR)
    return
  end
  if vim.trim(status) == "" then
    notify.send("Git", "Nothing to checkpoint", vim.log.levels.WARN)
    return
  end
  local branch, branch_err = git.run({ "rev-parse", "--abbrev-ref", "HEAD" }, cwd)
  if not branch then
    notify.send("Git", branch_err, vim.log.levels.ERROR)
    return
  end
  local message = ("chore(%s): checkpoint %s"):format(vim.trim(branch), os.date "%H:%M")
  run(
    cwd,
    { { "add", "--all" }, { "commit", "-m", message } },
    action("commit", "Creating checkpoint…", "Checkpoint committed: " .. message, "Checkpoint failed")
  )
end

-- Capture real paths before an asynchronous operation; Git-status section IDs
-- are virtual, and renames can require updating both index paths.
local function selected_paths(state, unstage)
  local node = state.tree and state.tree:get_node()
  if not node or node.type == "message" then
    return
  end
  local path = node.path or node:get_id()
  if not path then
    return
  end
  local paths = { path }
  local extra = node.extra or {}
  if extra.original_path and (unstage or extra.git_status == ".R" or extra.git_status == ".C") then
    paths[#paths + 1] = extra.original_path
  end
  return paths, node.name or vim.fn.fnamemodify(path, ":t")
end

function M.stage(state, all)
  local paths, name
  if not all then
    paths, name = selected_paths(state)
    if not paths then
      return
    end
  end
  local cwd = root(state)
  if not cwd then
    return
  end
  local args = { "add", "-A", "--" }
  vim.list_extend(args, all and { cwd } or paths)
  run(cwd, { args }, action("stage", "Staging…", all and "All changes staged" or ("Staged: " .. name), "Staging failed"), true)
end

function M.stage_all(state)
  M.stage(state, true)
end

function M.unstage(state)
  local paths, name = selected_paths(state, true)
  if not paths then
    return
  end
  local cwd = root(state)
  if not cwd then
    return
  end
  local head = git.run({ "rev-parse", "--verify", "HEAD" }, cwd)
  local args = head and { "reset", "-q", "HEAD", "--" } or { "rm", "--cached", "-r", "-f", "--ignore-unmatch", "--" }
  vim.list_extend(args, paths)
  run(cwd, { args }, action("unstage", "Unstaging…", "Unstaged: " .. name, "Unstaging failed"), true)
end

function M.revert(state)
  local paths, name = selected_paths(state)
  if not paths then
    return
  end
  local cwd = root(state)
  if not cwd then
    return
  end
  require("neo-tree.ui.inputs").confirm("Are you sure you want to revert " .. name .. "?", function(yes)
    if yes then
      local args = vim.list_extend({ "checkout", "HEAD", "--" }, paths)
      run(cwd, { args }, action("revert", "Reverting changes…", "Reverted: " .. name, "Could not revert changes"))
    end
  end)
end

return M
