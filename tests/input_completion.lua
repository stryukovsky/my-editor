-- Run: nvim --headless -u NONE -i NONE -l tests/input_completion.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local completion = require "configs.input_completion"
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
  vim.fn.mkdir(root .. "/ignored", "p")
  write "ignored/hidden.txt"

  -- A nested cwd must still yield paths relative to the repository root.
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
    "src/nested/modified.lua",
    "src/staged.lua",
    "deleted.lua",
    "src/nested/renamed.lua",
    "src/nested/new file.lua",
    "root.txt",
  } do
    assert(items[path] == "Changed file", "Missing changed path: " .. path)
  end
  assert(items["src/"] == "Changed folder")
  assert(items["src/nested/"] == "Changed folder")
  assert(items["topic/paths"] == "Current branch")
  assert(
    not items["old.lua"]
      and not items["clean.lua"]
      and not items["ignored/hidden.txt"]
  )
  assert(not items["./"] and not items["/"])
  local seen = {}
  for _, item in ipairs(vim.b.input_git_paths) do
    assert(not seen[item.word], "Duplicate: " .. item.word)
    seen[item.word] = true
  end
  items = suggestions "fix(src/ne"
  assert(completion.complete(1, "") == 4)
  assert(items["src/nested/"] and items["src/nested/modified.lua"])
  assert(not items["root.txt"])

  git("checkout", "--detach", "-q")
  open(root)
  assert(vim.wait(5000, function()
    return vim.b.input_git_paths ~= nil
  end))
  assert(suggestions("fix: ")["src/staged.lua"] == "Changed file")
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
