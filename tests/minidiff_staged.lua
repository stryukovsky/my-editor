-- Run with: nvim --headless -u NONE -l tests/minidiff_staged.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/mini_diff")
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/utils")
local diff = require "mini.diff"
diff.setup { view = { style = "sign" }, delay = { text_change = 10 }, options = { wrap_goto = true, linematch = 0 } }
local helpers = { parse = require("mini.diff.hunks_loader.staged").parse, project = require("mini.diff.navigation.staged").project }
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual))
end
local function wait(predicate, label)
  assert(vim.wait(4000, predicate, 10), label)
end
local root = "/tmp/opencode/minidiff-staged-" .. vim.fn.getpid()
assert(vim.fn.mkdir(root, "p") == 1)
local function git(...)
  local result = vim.system(vim.list_extend({ "git", "-C", root }, { ... }), { text = true }):wait()
  assert(result.code == 0, result.stderr)
  return result.stdout
end
git "init"
git("config", "user.email", "test@example.com")
git("config", "user.name", "Test")
local baseline = {}
for i = 1, 12 do
  baseline[i] = "line " .. i
end
vim.fn.writefile(baseline, root .. "/file.txt")
git("add", ".")
git("commit", "-m", "baseline")
vim.cmd.edit(root .. "/file.txt")
local buf = vim.api.nvim_get_current_buf()
local function settled(staged_count, unstaged_count)
  wait(function()
    local snapshot = diff.get_staged_data(buf)
    local data = diff.get_buf_data(buf)
    local state = diff.get_buf_state(buf)
    return state and state.status == "ready"
      and snapshot and snapshot.status == "ready"
      and #snapshot.hunks == staged_count and #snapshot.buffer_hunks == staged_count
      and data and #data.hunks == unstaged_count
  end, "snapshots did not settle: " .. staged_count .. "/" .. unstaged_count)
end
settled(0, 0)
local staged_lines = vim.deepcopy(baseline)
staged_lines[3], staged_lines[9] = "staged three", "staged nine"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, staged_lines)
vim.cmd.write()
git("add", "file.txt")
settled(2, 0)
local snapshot = diff.get_staged_data(buf)
equal(snapshot.hunks[1].buf_start, 3, "index coordinates")
snapshot.hunks[1].buf_start = 99
equal(diff.get_staged_data(buf).hunks[1].buf_start, 3, "snapshot is independent")
equal(diff.get_buf_data(buf).ref_text, table.concat(staged_lines, "\n") .. "\n", "normal reference remains index")
local _, H = debug.getupvalue(diff.enable, 1)
assert(H.cache, "engine helpers unavailable")
local function marker(line)
  local marks = vim.api.nvim_buf_get_extmarks(buf, H.ns_id.viz, { line - 1, 0 }, { line - 1, -1 }, { details = true })
  return marks[1] and marks[1][4] or H.cache[buf].viz_lines[line]
end
equal(vim.trim(marker(3).sign_text), "┆", "staged marker")
equal(marker(3).sign_hl_group, "MiniDiffSignStagedChange", "staged highlight")

-- Existing navigation can opt into staged targets without changing textobjects.
vim.api.nvim_win_set_cursor(0, { 1, 0 })
diff.goto_hunk("next", { staged = true })
equal(vim.fn.line("."), 3, "next staged hunk")
diff.goto_hunk("next", { staged = true })
equal(vim.fn.line("."), 9, "second staged hunk")
diff.goto_hunk("prev", { staged = true })
equal(vim.fn.line("."), 3, "previous staged hunk")
diff.goto_hunk("prev", { staged = true })
equal(vim.fn.line("."), 9, "backward wrap")
equal(#diff.get_contiguous_hunk_ranges(buf), 0, "unstaged ranges stay separate")

vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "unsaved one", "unsaved two" })
settled(2, 1)
equal(diff.get_staged_data(buf).hunks[1].buf_start, 3, "original index range retained")
equal(diff.get_staged_data(buf).buffer_hunks[1].buf_start, 5, "unsaved insertion projects staged range")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, baseline)
settled(2, 2)
equal(#diff.get_navigation_hunk_ranges(buf), 2, "reverse edits retain staged targets without duplicate stops")
equal(vim.trim(marker(3).sign_text), "╋", "mixed marker")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "all locally removed" })
settled(2, 1)
for _, hunk in ipairs(diff.get_staged_data(buf).buffer_hunks) do
  equal(hunk.buf_start, 1, "removed span anchor remains valid")
end

local messages, focused = {}, false
package.loaded["integrations.notify"] = {
  replace = function(_, _, message) messages[#messages + 1] = message end,
  send = function(_, message) messages[#messages + 1] = message end,
}
package.loaded["moonshine.diff.review"] = { setup = function() end }
package.loaded["moonshine.diff.history"] = { setup = function() end }
package.loaded["moonshine.utils.ui_prevent_mess"] = function() end
package.loaded["moonshine.utils.focus_neotree"] = function() focused = true end
local integration = require "moonshine.diff"
vim.api.nvim_buf_set_lines(buf, 0, -1, false, staged_lines)
settled(2, 0)
local index_before = git("show", ":file.txt")
integration.reset_hunk()
integration.reset_buffer()
integration.select()
integration.preview()
assert(messages[#messages]:find("Only staged", 1, true), "staged-only action feedback")
equal(git("show", ":file.txt"), index_before, "staged-only actions never change index")
equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), staged_lines, "staged-only actions preserve buffer")
local mappings = {}
package.loaded["mappings.map"] = function(_, key, callback) mappings[key] = callback end
dofile "lua/mappings/minidiff.lua"
vim.api.nvim_win_set_cursor(0, { 1, 0 })
mappings["]g"]()
equal(vim.fn.line("."), 3, "existing next mapping reaches staged hunk")
local navigation_repeat = require "moonshine.utils.navigation_repeat"
navigation_repeat.repeat_next()
equal(vim.fn.line("."), 9, "repeat reaches next staged hunk")
navigation_repeat.repeat_previous()
equal(vim.fn.line("."), 3, "repeat reaches previous staged hunk")
vim.api.nvim_buf_set_lines(buf, 11, 12, false, { "unstaged twelve" })
settled(2, 1)
vim.api.nvim_win_set_cursor(0, { 9, 0 })
equal(integration.lualine_hunks(), "hunks: 2/3", "combined position count")
integration.reset_hunk()
integration.preview()
integration.select()
assert(messages[#messages]:find("Only staged changes here", 1, true), "mixed-file staged target feedback")
equal(git("show", ":file.txt"), index_before, "mixed-file staged target actions preserve index")
integration.nav(1)
equal(vim.fn.line("."), 12, "last staged hunk does not hand off early")
assert(not focused)
integration.nav(1)
assert(focused, "last combined target hands off")
integration.reset_hunk()
settled(2, 0)
equal(git("show", ":file.txt"), index_before, "unstaged reset leaves staged snapshot untouched")

-- A commit changes HEAD with no change to index contents.
git("commit", "-m", "staged changes")
settled(0, 0)
git("reset", "--soft", "HEAD^")
settled(2, 0)
git("reset", "--", "file.txt")
settled(0, 2)
git("add", "file.txt")
settled(2, 0)
git("commit", "-m", "restage")
settled(0, 0)
git("branch", "alternate", "HEAD^")
git("switch", "alternate")
wait(function()
  local data = diff.get_buf_data(buf)
  return data and data.ref_text == table.concat(baseline, "\n") .. "\n"
end, "branch switch did not refresh index reference")
settled(0, 2)
git("rm", "file.txt")
settled(1, 1)
equal(diff.get_staged_data(buf).hunks[1].type, "delete", "whole-file staged deletion")
assert(diff.get_staged_data(buf).buffer_hunks[1].buf_start <= vim.api.nvim_buf_line_count(buf), "deleted file target is reachable")
git("restore", "--staged", "--worktree", "file.txt")
settled(0, 2)

-- Obsolete staged callbacks cannot replace a newer snapshot or revive buffers.
local read_reference, pending = H.git_read_reference, {}
H.git_read_reference = function(args, cwd, callback)
  if args[1] == "diff" then
    pending[#pending + 1] = callback
  else
    read_reference(args, cwd, callback)
  end
end
H.git_set_ref_text(buf)
wait(function() return #pending == 1 end, "first staged read")
H.git_set_ref_text(buf)
wait(function() return #pending == 2 end, "second staged read")
pending[1](0, "@@ -1 +1 @@\n")
assert(diff.get_staged_state(buf).status ~= "ready", "obsolete staged result ignored")
pending[2](1, "", "staged read test failure")
wait(function() return diff.get_staged_state(buf).status == "failed" end, "staged failure settles")
equal(#diff.get_staged_data(buf).hunks, 0, "failed staged reads clear stale hunks")
H.git_set_ref_text(buf)
wait(function() return #pending == 3 end, "pending read before disable")
diff.disable(buf)
pending[3](0, "@@ -1 +1 @@\n")
equal(diff.get_staged_data(buf), nil, "late staged callback cannot reattach")
H.git_read_reference = read_reference

-- Linked worktrees keep their branch refs outside the per-worktree Git dir.
local main_root = root
git("worktree", "add", "-b", "linked-test", root .. "/linked", "HEAD")
root = root .. "/linked"
git("config", "core.logAllRefUpdates", "false")
vim.cmd.edit(root .. "/file.txt")
buf = vim.api.nvim_get_current_buf()
settled(0, 0)
vim.api.nvim_buf_set_lines(buf, 2, 3, false, { "linked staged change" })
vim.cmd.write()
git("add", "file.txt")
settled(1, 0)
git("commit", "-m", "linked commit")
settled(0, 0)
git("reset", "--soft", "HEAD^")
settled(1, 0)
diff.disable(buf)
root = main_root

-- No HEAD yet: Git's cached diff supplies an empty baseline for additions.
root = root .. "/unborn"
assert(vim.fn.mkdir(root, "p") == 1)
git "init"
vim.fn.writefile({ "new file" }, root .. "/new.txt")
git("add", "new.txt")
vim.cmd.edit(root .. "/new.txt")
buf = vim.api.nvim_get_current_buf()
settled(1, 0)
equal(diff.get_staged_data(buf).hunks[1].type, "add", "unborn staged addition")
equal(marker(1).sign_hl_group, "MiniDiffSignStagedAdd", "addition highlight")

local parsed = helpers.parse("@@ -2,2 +1,0 @@\n")
equal(parsed[1].type, "delete", "staged deletion")
equal(helpers.project(parsed, {}, 1)[1].buf_start, 1, "deletion boundary anchor")
local binary, reason = helpers.parse("Binary files a/file and b/file differ\n")
assert(not binary and reason:find("Binary", 1, true))
assert(not helpers.parse("* Unmerged path file\n"))
diff.disable(buf)
vim.fn.delete(vim.fn.fnamemodify(root, ":h"), "rf")
print "minidiff staged: all checks passed"
