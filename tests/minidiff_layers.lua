-- Run with: nvim --headless -u NONE -l tests/minidiff_layers.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/mini_diff")
local diff = require "mini.diff"
diff.setup { view = { style = "sign" }, delay = { text_change = 300 }, options = { wrap_goto = true, linematch = 0 } }
local helpers = { parse = require("mini.diff.hunks_loader.staged").parse, project = require("mini.diff.navigation.staged").project }
local failures = {}
local function check(condition, label)
  if not condition then failures[#failures + 1] = label end
end
local function wait(predicate, label)
  assert(vim.wait(4000, predicate, 10), label)
end
local root = "/tmp/opencode/minidiff-layers-" .. vim.fn.getpid()
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
for i = 1, 20 do baseline[i] = "line " .. i end
vim.fn.writefile(baseline, root .. "/file.txt")
git("add", ".")
git("commit", "-m", "baseline")
vim.cmd.edit(root .. "/file.txt")
local buf = vim.api.nvim_get_current_buf()
local _, H = debug.getupvalue(diff.enable, 1)
local function settled(staged_count, unstaged_count)
  wait(function()
    local staged, data, state = diff.get_staged_data(buf), diff.get_buf_data(buf), diff.get_buf_state(buf)
    return staged and staged.status == "ready" and #staged.buffer_hunks == staged_count
      and data and #data.hunks == unstaged_count and state and state.status == "ready"
  end, "snapshots did not settle")
end
settled(0, 0)
local messages, focused = {}, false
package.loaded["integrations.notify"] = {
  replace = function(_, _, text) messages[#messages + 1] = text end,
  send = function(_, text) messages[#messages + 1] = text end,
}
package.loaded["moonshine.diff.review"] = { setup = function() end }
package.loaded["moonshine.diff.history"] = { setup = function() end }
package.loaded["moonshine.utils.ui_prevent_mess"] = function() end
package.loaded["moonshine.utils.focus_neotree"] = function() focused = true end
local integration = require "moonshine.diff"

-- These strings are ordinary source text, not Git patch metadata.
for _, text in ipairs({ "Binary files", "GIT binary patch", "* Unmerged path", "diff --cc" }) do
  local hunks = helpers.parse("diff --git a/file b/file\n--- a/file\n+++ b/file\n@@ -1 +1 @@\n-old\n+" .. text .. "\n")
  check(hunks and #hunks == 1, "source text misclassified as metadata: " .. text)
end

vim.api.nvim_buf_set_lines(buf, 3, 4, false, { "staged four" })
vim.cmd.write()
git("add", "file.txt")
settled(1, 0)
vim.api.nvim_buf_set_lines(buf, 9, 10, false, { "saved ten" })
vim.cmd.write()
settled(1, 1)
vim.api.nvim_buf_set_lines(buf, 15, 16, false, { "unsaved sixteen" })
vim.api.nvim_win_set_cursor(0, { 11, 0 })
integration.nav(1)
check(vim.fn.line(".") == 16, "navigation misses fresh unsaved edits during debounce")
settled(1, 2)
local ranges = diff.get_navigation_hunk_ranges(buf)
check(#ranges == 3 and ranges[1].from == 4 and ranges[2].from == 10 and ranges[3].from == 16, "three-layer ordered hunk union")
check(git("show", ":file.txt"):find("line 16", 1, true), "navigation never writes unsaved edits into index")
check(vim.fn.readfile(root .. "/file.txt")[16] == "line 16", "navigation never saves unsaved buffer")

-- Stage the saved state without saving the extra buffer edit.
git("add", "file.txt")
settled(2, 1)
check(vim.bo[buf].modified, "staging saved text preserves modified buffer")
check(diff.get_navigation_hunk_ranges(buf)[3].from == 16, "unsaved target survives staging saved changes")
vim.api.nvim_win_set_cursor(0, { 10, 0 })
integration.nav(1)
check(vim.fn.line(".") == 16 and not focused, "saved-to-staged transition does not cause early handoff")

-- Switching buffers should not manufacture a loading cycle for unchanged refs.
local before = H.git_cache[buf].request
local scratch = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(scratch)
vim.api.nvim_set_current_buf(buf)
vim.wait(100, function() return false end)
check(H.git_cache[buf].request == before, "buffer switching restarts already current Git reads")
settled(2, 1)

-- Deliver the index first, then the staged patch before projection can run.
local read_reference, pending = H.git_read_reference, {}
H.git_read_reference = function(args, _, callback) pending[args[1]] = callback end
H.git_set_ref_text(buf)
wait(function() return pending.show and pending.diff end, "controlled reads did not start")
pending.show(0, git("show", ":file.txt"))
wait(function() return diff.get_buf_state(buf).status == "ready" end, "index did not settle")
pending.diff(0, "@@ -4 +4 @@\n@@ -10 +10 @@\n")
local staged = diff.get_staged_data(buf)
check(staged.status ~= "ready" or #staged.buffer_hunks == 2, "staged snapshot becomes ready before its navigation anchors")
settled(2, 1)

-- The opposite callback order also stays pending until anchors are current.
pending = {}
H.git_set_ref_text(buf)
wait(function() return pending.show and pending.diff end, "reverse-order reads did not start")
pending.diff(0, "@@ -4 +4 @@\n@@ -10 +10 @@\n")
check(diff.get_staged_state(buf).status ~= "ready", "staged-first read publishes premature readiness")
vim.api.nvim_win_set_cursor(0, { 2, 0 })
integration.nav(1)
check(vim.fn.line(".") == 2, "pending references must not navigate stale targets")
pending.show(0, git("show", ":file.txt"))
settled(2, 1)
check(vim.fn.line(".") == 2, "blocked navigation must not replay after Git reads")

-- A later successful staged read must not erase an index-read failure.
pending = {}
H.git_set_ref_text(buf)
wait(function() return pending.show and pending.diff end, "failure reads did not start")
pending.show(1, "", "index read failure")
pending.diff(0, "@@ -4 +4 @@\n")
vim.wait(100, function() return false end)
check(diff.get_staged_state(buf).status ~= "ready", "staged anchors become ready using a failed index read")
H.git_read_reference = read_reference
H.git_set_ref_text(buf)
settled(2, 1)

-- Untracked files and their unsaved edits are ordinary added hunks too.
vim.fn.writefile({ "new saved line" }, root .. "/new.txt")
vim.cmd.edit(root .. "/new.txt")
buf = vim.api.nvim_get_current_buf()
wait(function()
  local state = diff.get_buf_state(buf)
  return state and state.status ~= "loading" and state.status ~= "updating"
end, "untracked buffer did not settle")
check(diff.get_buf_state(buf).status == "ready", "untracked file has no usable empty index baseline")
vim.api.nvim_buf_set_lines(buf, -1, -1, false, { "new unsaved line" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
integration.nav(-1)
check(vim.fn.line(".") == 1, "untracked unsaved hunk is not navigable")
git("add", "new.txt")
settled(1, 1)
check(vim.api.nvim_buf_get_lines(buf, 0, -1, false)[2] == "new unsaved line", "staging a new file preserves its extra unsaved edit")
check(#diff.get_navigation_hunk_ranges(buf) == 1, "adjacent new-file layers form one hunk target")

vim.cmd.edit(root .. "/not-created.txt")
buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "only in memory", "second unsaved line" })
settled(0, 1)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
integration.nav(-1)
check(vim.fn.line(".") == 1, "new unsaved file has a navigable added hunk")
check(vim.fn.filereadable(root .. "/not-created.txt") == 0, "navigation never creates a new unsaved file")

vim.fn.writefile({ "ignored.txt" }, root .. "/.gitignore")
vim.fn.writefile({ "ignored content" }, root .. "/ignored.txt")
vim.cmd.edit({ args = { root .. "/ignored.txt" }, bang = true })
buf = vim.api.nvim_get_current_buf()
wait(function()
  local state = diff.get_buf_state(buf)
  return state and state.status ~= "loading" and state.status ~= "updating"
end, "ignored buffer did not settle")
check(diff.get_buf_state(buf).status == "unavailable", "ignored files must not get untracked addition hunks")

local projection_cases = {
  { { ref_start = 2, ref_count = 0, buf_start = 3, buf_count = 2 }, 5, 7 },
  { { ref_start = 1, ref_count = 2, buf_start = 0, buf_count = 0 }, 1, 3 },
  { { ref_start = 3, ref_count = 3, buf_start = 2, buf_count = 0 }, 2, 2 },
  { { ref_start = 3, ref_count = 3, buf_start = 3, buf_count = 1 }, 3, 3 },
}
for i, case in ipairs(projection_cases) do
  local projected = helpers.project({ { type = "change", buf_start = 3, buf_count = 3, ref_start = 3, ref_count = 3 } }, { case[1] }, 20)[1]
  check(projected.buf_start == case[2] and projected.buf_start + projected.buf_count - 1 == case[3], "staged range projection case " .. i)
end

for candidate in pairs(H.git_cache) do
  if H.cache[candidate] then diff.disable(candidate) end
end
vim.fn.delete(root, "rf")
assert(#failures == 0, "layer regressions:\n- " .. table.concat(failures, "\n- "))
print "minidiff layers: all checks passed"
