local git = require "configs.gitutils"
local notify = require "configs.notify"
local M = { busy = {} }

local function root()
  local cwd, err = git.root()
  if not cwd then
    notify.send("Git", err, vim.log.levels.ERROR)
  end
  return cwd
end

local function run(cwd, args, message, callback)
  if M.busy[cwd] then
    notify.send("Git", "Another Git command is running", vim.log.levels.WARN)
    return
  end
  local fetch = package.loaded["configs.periodic-git-fetch"]
  if fetch and fetch.fetch_pending then
    notify.send(
      "Git",
      "Background fetch is running; try again shortly",
      vim.log.levels.WARN
    )
    return
  end
  M.busy[cwd] = true
  notify.send("Git", "Running git " .. args[1] .. "…")
  git.job {
    cwd = cwd,
    args = args,
    on_exit = function(code, stderr, stdout)
      vim.schedule(function()
        M.busy[cwd] = nil
        -- Failed Git commands can also change the index/worktree (e.g. merge conflicts).
        if package.loaded["neo-tree"] then
          local events = require "neo-tree.events"
          events.fire_event(events.GIT_EVENT)
        end
        if code ~= 0 then
          local error = stderr ~= "" and stderr or stdout
          notify.send(
            "Git",
            error ~= "" and error or "Git command failed",
            vim.log.levels.ERROR
          )
          return
        end
        if callback then
          callback()
          return
        end
        local output = vim.trim(stdout)
        notify.send(
          "Git",
          output ~= "" and (message .. "\n" .. output) or message
        )
        if stderr:lower():find("conflict", 1, true) then
          notify.send("Git", stderr, vim.log.levels.WARN)
        end
        vim.cmd "checktime"
        local fetch = package.loaded["configs.periodic-git-fetch"]
        if fetch then
          fetch.refresh_sync_state(cwd, true)
        end
      end)
    end,
  }
end

local function command(args, message)
  local cwd = root()
  if cwd then
    run(cwd, args, message)
  end
end

function M.pull()
  command({ "pull", "--rebase", "--autostash" }, "Pull finished")
end

function M.push()
  -- Establish tracking automatically on the first push of a new branch.
  command({ "-c", "push.autoSetupRemote=true", "push" }, "Push finished")
end

function M.fetch()
  command({ "fetch" }, "Fetch finished")
end

function M.merge_continue()
  command({ "-c", "core.editor=true", "merge", "--continue" }, "Merge finished")
end

function M.merge_abort()
  command({ "merge", "--abort" }, "Merge aborted")
end

function M.stash()
  command({ "stash", "push", "--include-untracked" }, "Stash finished")
end

function M.stash_pop()
  command({ "stash", "pop" }, "Stash pop finished")
end

local function input_command(prompt, args, message, default)
  local cwd = root()
  if not cwd then
    return
  end
  vim.ui.input({ prompt = prompt, default = default }, function(value)
    if not value or vim.trim(value) == "" then
      return
    end
    local command_args = vim.list_extend(vim.deepcopy(args), { value })
    run(cwd, command_args, message .. value)
  end)
end

function M.branch_create()
  input_command("New branch: ", { "switch", "-c" }, "Switched to new branch: ")
end

function M.branch_rename()
  local cwd = root()
  if not cwd then
    return
  end
  local branch, err =
    git.run({ "symbolic-ref", "--quiet", "--short", "HEAD" }, cwd)
  if not branch then
    notify.send("Git", err, vim.log.levels.ERROR)
    return
  end
  input_command(
    "Rename current branch: ",
    { "branch", "-m" },
    "Renamed branch to: ",
    vim.trim(branch)
  )
end

function M.commit()
  input_command("Commit message: ", { "commit", "-m" }, "Committed: ")
end

function M.checkpoint()
  local cwd = root()
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
  local branch, branch_err =
    git.run({ "rev-parse", "--abbrev-ref", "HEAD" }, cwd)
  if not branch then
    notify.send("Git", branch_err, vim.log.levels.ERROR)
    return
  end
  local message = ("chore(%s): checkpoint %s"):format(
    vim.trim(branch),
    os.date "%H:%M"
  )
  run(cwd, { "add", "--all" }, "", function()
    run(cwd, { "commit", "-m", message }, message)
  end)
end

return M
