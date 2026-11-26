-- nvim --headless -u NONE -i NONE -l tests/git_lazy_commit.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd() .. "/moonshine.nvim/git_tools")
package.loaded["integrations.notify"] = {
  send = function() end,
  replace = function() end,
}

local git = require "moonshine.git"
local scheduler = require "moonshine.git.scheduler"
local commands = require "moonshine.git.commands"
local dir = "/tmp/opencode/nvim-lazy-commit-" .. vim.uv.os_getpid()
vim.fn.mkdir(dir, "p")

local function command(args)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local result = vim.system(cmd, { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout)
end

command { "init", "-q" }
command { "config", "user.name", "Test User" }
command { "config", "user.email", "test@example.com" }
vim.fn.writefile({ "initial" }, dir .. "/staged.txt")
vim.fn.writefile({ "initial" }, dir .. "/unstaged.txt")
command { "add", "--all" }
command { "commit", "-q", "-m", "Previous subject", "-m", "Previous body" }
local previous = command { "rev-parse", "HEAD" }
local message = command { "log", "-1", "--format=%B" }

vim.fn.writefile({ "changed" }, dir .. "/staged.txt")
vim.fn.writefile({ "changed" }, dir .. "/unstaged.txt")
command { "add", "staged.txt" }
commands.lazy_commit { path = dir }
assert(
  vim.wait(5000, function()
    return scheduler.busy == nil
  end),
  "Lazy commit timed out"
)
assert(
  command { "rev-parse", "HEAD" } ~= previous,
  "Expected a new commit, not an amend"
)
assert(
  command { "log", "-1", "--format=%B" } == message,
  "Commit message was not reused"
)
assert(
  command { "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD" }
    == "staged.txt",
  "Committed unstaged files"
)
assert(
  command { "diff", "--name-only" } == "unstaged.txt",
  "Unstaged changes were lost"
)

local latest = command { "rev-parse", "HEAD" }
commands.lazy_commit { path = dir }
assert(
  scheduler.busy == nil,
  "No-staged-files action should finish immediately"
)
assert(
  command { "rev-parse", "HEAD" } == latest,
  "Committed without staged files"
)
vim.fn.delete(dir, "rf")
print "Lazy commit checks passed"
