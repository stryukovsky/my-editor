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
equal(marker(3).sign_hl_group, "MiniDiffSignChange", "reverse edit keeps unstaged marker")
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
vim.fn.writefile(baseline, root .. "/new.txt")
git("add", "new.txt")
vim.cmd.edit(root .. "/new.txt")
buf = vim.api.nvim_get_current_buf()
settled(1, 0)
equal(diff.get_staged_data(buf).hunks[1].type, "add", "unborn staged addition")
equal(marker(1).sign_hl_group, "MiniDiffSignStagedAdd", "addition highlight")

-- A staged whole-file addition must not swallow newer unstaged edits.
local staged_addition = diff.get_staged_data(buf).hunks
local addition_index = git("show", ":new.txt")
local function edit_addition(lines, count)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  diff.flush_buf_diff(buf)
  settled(1, count)
  vim.cmd.redraw()
end
local function segments(expected, label)
  local actual = {}
  for _, range in ipairs(diff.get_navigation_hunk_ranges(buf)) do
    actual[#actual + 1] = { range.from, range.to }
  end
  equal(actual, expected, label)
end
local inside = vim.deepcopy(baseline)
inside[5] = "unstaged five"
edit_addition(inside, 1)
segments({ { 1, 4 }, { 5, 5 }, { 6, 12 } }, "split staged addition around edit")
equal(marker(5).sign_hl_group, "MiniDiffSignChange", "overlap keeps unstaged change sign")
equal(vim.trim(marker(5).sign_text), vim.trim(H.cache[buf].extmark_opts.change.sign_text), "overlap keeps unstaged change glyph")
equal(marker(4).sign_hl_group, "MiniDiffSignStagedAdd", "preceding staged sign")
equal(marker(6).sign_hl_group, "MiniDiffSignStagedAdd", "following staged sign")
vim.cmd.write()
settled(1, 1)
segments({ { 1, 4 }, { 5, 5 }, { 6, 12 } }, "saving preserves split edit locations")
inside[9] = "unstaged nine"
edit_addition(inside, 2)
segments({ { 1, 4 }, { 5, 5 }, { 6, 8 }, { 9, 9 }, { 10, 12 } }, "multiple contained edits")
for _, enabled in ipairs { true, false } do
  integration.toggle_overlay()
  wait(function() return diff.get_buf_data(buf).overlay == enabled end, "overlap overlay toggle")
  diff.flush_buf_diff(buf)
  vim.cmd.redraw()
  equal(marker(5).sign_hl_group, "MiniDiffSignChange", "overlay toggle retains unstaged precedence")
  equal(marker(6).sign_hl_group, "MiniDiffSignStagedAdd", "overlay toggle retains staged remainder")
  segments({ { 1, 4 }, { 5, 5 }, { 6, 8 }, { 9, 9 }, { 10, 12 } }, "overlay toggle preserves segments")
end

-- Mappings, repeat, counts, and handoff all use these same adjacent stops.
focused = false
vim.api.nvim_win_set_cursor(0, { 1, 0 })
equal(integration.lualine_hunks(), "hunks: 1/5", "first staged segment position")
mappings["]g"]()
equal(vim.fn.line("."), 5, "mapping reaches contained unstaged edit")
equal(integration.lualine_hunks(), "hunks: 2/5", "contained unstaged position")
navigation_repeat.repeat_next()
equal(vim.fn.line("."), 6, "repeat reaches staged remainder")
navigation_repeat.repeat_next()
equal(vim.fn.line("."), 9, "repeat reaches second unstaged edit")
navigation_repeat.repeat_next()
equal(vim.fn.line("."), 10, "repeat reaches final staged remainder")
assert(not focused, "no early handoff within split addition")
equal(integration.lualine_hunks(), "hunks: 5/5", "final staged segment position")
navigation_repeat.repeat_previous()
equal(vim.fn.line("."), 9, "backward repeat respects layer boundary")
mappings["[g"]()
equal(vim.fn.line("."), 6, "previous mapping reaches staged segment")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
mappings["[g"]()
equal(vim.fn.line("."), 10, "split segment backward wrap")
navigation_repeat.repeat_next()
assert(focused, "handoff only after final split segment")

-- Split staged ranges never become mutation or selection ranges.
vim.api.nvim_win_set_cursor(0, { 4, 0 })
equal(diff.get_contiguous_hunk_range_at_cursor(buf), nil, "staged segment has no action range")
integration.reset_hunk()
equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), inside, "staged segment reset does nothing")
integration.preview()
equal(vim.api.nvim_get_current_buf(), buf, "staged segment has no unstaged preview")
vim.api.nvim_win_set_cursor(0, { 5, 0 })
equal(diff.get_contiguous_hunk_range_at_cursor(buf), { from = 5, to = 5 }, "real unstaged action range")
integration.preview()
local overlap_preview = vim.api.nvim_get_current_buf()
assert(overlap_preview ~= buf, "contained unstaged preview opened")
equal(vim.api.nvim_buf_get_lines(overlap_preview, 0, -1, false), { baseline[5], inside[5] }, "preview contains only real unstaged hunk")
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_delete(overlap_preview, { force = true })
vim.api.nvim_win_set_cursor(0, { 5, 0 })
integration.select()
equal({ vim.fn.line("v"), vim.fn.line(".") }, { 5, 5 }, "selection excludes staged segments")
vim.cmd "normal! \27"
integration.reset_hunk()
settled(1, 1)
local reset = vim.deepcopy(inside)
reset[5] = baseline[5]
equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), reset, "reset changes only selected unstaged hunk")
equal(git("show", ":new.txt"), addition_index, "split navigation and actions preserve index")
equal(diff.get_staged_data(buf).hunks, staged_addition, "staged snapshot remains intact")

local inserted = vim.deepcopy(baseline)
table.insert(inserted, 1, "new first line")
edit_addition(inserted, 1)
segments({ { 1, 1 }, { 2, 13 } }, "insertion above staged range remains separate")
equal(marker(1).sign_hl_group, "MiniDiffSignAdd", "unstaged insertion sign")
equal(vim.trim(marker(1).sign_text), vim.trim(H.cache[buf].extmark_opts.add.sign_text), "unstaged insertion glyph")
equal(marker(2).sign_hl_group, "MiniDiffSignStagedAdd", "shifted staged addition sign")
inserted = vim.deepcopy(baseline)
table.insert(inserted, 5, "new middle line")
edit_addition(inserted, 1)
segments({ { 1, 4 }, { 5, 5 }, { 6, 13 } }, "interior insertion splits staged span")
equal(marker(5).sign_hl_group, "MiniDiffSignAdd", "interior unstaged add sign")

local deleted = vim.deepcopy(baseline)
table.remove(deleted, 5)
edit_addition(deleted, 1)
segments({ { 1, 3 }, { 4, 4 }, { 5, 11 } }, "deletion anchor splits staged span")
equal(marker(4).sign_hl_group, "MiniDiffSignDelete", "overlapping deletion anchor stays unstaged")
equal(vim.trim(marker(4).sign_text), vim.trim(H.cache[buf].extmark_opts.delete.sign_text), "unstaged deletion anchor glyph")
deleted = vim.deepcopy(baseline)
table.remove(deleted, 1)
edit_addition(deleted, 1)
segments({ { 1, 1 }, { 2, 11 } }, "start deletion anchor remains reachable")

local replaced = {}
for i = 1, #baseline do replaced[i] = "replacement " .. i end
edit_addition(replaced, 1)
segments({ { 1, 12 } }, "complete overlap has one unstaged target")
equal(marker(1).sign_hl_group, "MiniDiffSignChange", "complete overlap stays unstaged")
edit_addition({}, 1)
segments({ { 1, 1 } }, "removed staged file has one valid deletion anchor")
equal(marker(1).sign_hl_group, "MiniDiffSignChange", "empty buffer replacement stays unstaged")
edit_addition(baseline, 0)
segments({ { 1, 12 } }, "staged-only addition remains one target")

local parsed = helpers.parse("@@ -2,2 +1,0 @@\n")
equal(parsed[1].type, "delete", "staged deletion")
equal(helpers.project(parsed, {}, 1)[1].buf_start, 1, "deletion boundary anchor")
local binary, reason = helpers.parse("Binary files a/file and b/file differ\n")
assert(not binary and reason:find("Binary", 1, true))
assert(not helpers.parse("* Unmerged path file\n"))
diff.disable(buf)
vim.fn.delete(vim.fn.fnamemodify(root, ":h"), "rf")
print "minidiff staged: all checks passed"
