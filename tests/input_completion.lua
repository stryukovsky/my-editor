-- Run: nvim --headless -u NONE -i NONE -l tests/input_completion.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(
  vim.fn.glob(vim.fn.getcwd() .. "/moonshine.nvim/*", true, true)
)
local completion = require "moonshine.input.completion"
local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/src/nested", "p")

local function git(...)
  local result = vim
    .system(vim.list_extend({ "git", "-C", root }, { ... }), { text = true })
    :wait()
  assert(result.code == 0, result.stderr)
  return vim.trim(result.stdout or "")
end

local function write(path)
  vim.fn.writefile({ "content" }, root .. "/" .. path)
end

local function open(cwd)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  completion.setup(buf, cwd)
  return buf
end

local function suggestions(text)
  vim.api.nvim_set_current_line(text)
  vim.api.nvim_win_set_cursor(0, { 1, #text })
  local result = {}
  for _, item in ipairs(completion.complete(0, "").words) do
    result[item.word] = item.menu
  end
  return result
end

local ok, err = xpcall(function()
  git("init", "-q", "-b", "topic/paths")
  for _, path in ipairs {
    "src/nested/modified.lua",
    "src/staged.lua",
    "deleted.lua",
    "old.lua",
    "clean.lua",
    ".gitignore",
  } do
    write(path)
  end
  vim.fn.writefile({ "ignored/" }, root .. "/.gitignore")
  git("add", ".")
  git(
    "-c",
    "user.name=Test",
    "-c",
    "user.email=test@example.com",
    "commit",
    "-qm",
    "initial"
  )
  vim.fn.writefile({ "changed" }, root .. "/src/nested/modified.lua")
  vim.fn.writefile({ "staged" }, root .. "/src/staged.lua")
  git("add", "src/staged.lua")
  vim.fn.delete(root .. "/deleted.lua")
  git("mv", "old.lua", "src/nested/renamed.lua")
  write "src/nested/new file.lua"
  write "root.txt"
  vim.fn.mkdir(root .. "/test/my-research", "p")
  write "test/my-research/PoolManager.swap.t.sol"
  write "src/nested/PoolManager.swap.t.sol"
  vim.fn.mkdir(root .. "/ignored", "p")
  write "ignored/hidden.txt"

  -- A nested cwd must still find names from the whole repository.
  open(root .. "/src/nested")
  assert(
    vim.wait(5000, function()
      return vim.b.input_git_paths ~= nil and vim.b.input_git_branch ~= nil
    end),
    "Git suggestions did not load"
  )
  vim.o.virtualedit = "onemore"
  local items = suggestions "fix: "
  for _, path in ipairs {
    "modified.lua",
    "staged.lua",
    "deleted.lua",
    "renamed.lua",
    "new file.lua",
    "root.txt",
  } do
    assert(items[path] == "Changed file", "Missing changed path: " .. path)
  end
  assert(items["src"] == "Changed folder")
  assert(items["nested"] == "Changed folder")
  assert(items["test"] == "Changed folder")
  assert(items["my-research"] == "Changed folder")
  assert(not items["topic/paths"])
  for word in pairs(items) do
    assert(not word:find("/", 1, true), "Slash in suggestion: " .. word)
  end
  vim.b.input_git_branch = "main"
  assert(suggestions("fix: ")["main"] == "Current branch")
  vim.b.input_git_branch = "topic/paths"
  assert(
    not items["old.lua"]
      and not items["clean.lua"]
      and not items["hidden.txt"]
      and not items["ignored"]
  )
  assert(not items["./"] and not items["/"])
  local seen = {}
  for _, item in ipairs(vim.b.input_git_paths) do
    assert(not seen[item.word], "Duplicate: " .. item.word)
    seen[item.word] = true
  end
  items = suggestions "fix(ne"
  assert(completion.complete(1, "") == 4)
  assert(items["nested"] and items["new file.lua"])
  assert(not items["root.txt"])
  items = suggestions "fix(PoolManager"
  assert(completion.complete(1, "") == 4)
  assert(items["PoolManager.swap.t.sol"] == "Changed file")
  assert(not items["test/my-research/PoolManager.swap.t.sol"])
  local count = 0
  for _, item in ipairs(completion.complete(0, "").words) do
    if item.word == "PoolManager.swap.t.sol" then
      count = count + 1
    end
  end
  assert(count == 1, "Duplicate basename suggestions")

  git("checkout", "--detach", "-q")
  open(root)
  assert(vim.wait(5000, function()
    return vim.b.input_git_paths ~= nil
  end))
  assert(suggestions("fix: ")["staged.lua"] == "Changed file")
  assert(vim.b.input_git_branch == nil)

  local outside = root .. "-outside"
  vim.fn.mkdir(outside, "p")
  local buf = open(outside)
  -- Let failed asynchronous Git callbacks finish, including a closed buffer.
  vim.wait(200, function()
    return false
  end)
  assert(vim.b.input_git_paths == nil and vim.b.input_git_branch == nil)
  assert(next(suggestions "fix: ") == nil)
  vim.api.nvim_buf_delete(buf, { force = true })
  buf = open(root)
  vim.api.nvim_buf_delete(buf, { force = true })
  vim.wait(200, function()
    return false
  end)
  vim.fn.delete(outside, "rf")
end, debug.traceback)
vim.fn.delete(root, "rf")
assert(ok, err)
print "PASS changed files, parent folders, fuzzy matching, nested cwd, renames, detached HEAD, and non-Git input"
