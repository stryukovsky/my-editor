-- Run with: nvim --headless -u NONE -l tests/jumper.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/jumper.nvim")
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/utils")
vim.opt.rtp:prepend(vim.fn.getcwd())
package.loaded["integrations.notify"] = { replace = function() end }
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")

local function check(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": expected " .. vim.inspect(expected) .. ", got " .. vim.inspect(actual))
end

local function store_checks()
  local store_module = require "moonshine.jumper.store"
  local path = root .. "/marks.json"
  local store = store_module.new(path)
  assert(store:load())
  assert(store:set("p", { path = root .. "/a", row = 2, col = 3 }))
  assert(store:set("p", { path = root .. "/b", row = 4, col = 0 }))
  check(store_module.new(path):load(), true, "reload")
  local reloaded = store_module.new(path)
  assert(reloaded:load())
  check(reloaded.marks.p, { path = root .. "/b", row = 4, col = 0 }, "overwrite persists")
  assert(not store:set("P", { path = root .. "/b", row = 1, col = 0 }))
  vim.fn.writefile({ "broken" }, path)
  local broken = store_module.new(path)
  assert(not broken:load())
  assert(not broken:set("z", { path = root .. "/b", row = 1, col = 0 }))
  check(vim.fn.readfile(path), { "broken" }, "invalid store preserved")
end

store_checks()

local function file(path, lines)
  vim.fn.writefile(lines, path)
  vim.cmd.edit { args = { path } }
  return vim.api.nvim_get_current_buf()
end

local function mark_checks()
  local jumper = require "moonshine.jumper"
  local a, b = root .. "/A", root .. "/B"
  local path = root .. "/persistent.json"
  jumper.setup { path = path }
  local first = file(a, { "one", "two", "three" })
  vim.api.nvim_win_set_cursor(0, { 2, 1 })
  assert(jumper.set "p")
  check(jumper.letters(first, 2), "p", "mark letter at line")
  assert(jumper.set "q")
  check(jumper.letters(first, 2), "pq", "multiple letters on line")
  assert(jumper.delete "q")
  check(jumper.letters(first, 2), "p", "removed letter")
  vim.api.nvim_buf_set_lines(first, 0, 0, false, { "inserted" })
  check(jumper.get("p").row, 3, "edit tracks line")
  check(jumper.letters(first, 3), "p", "mark letter follows edit")
  check(jumper.letters(first, 2), "", "old line clears")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  assert(jumper.jump "p", "jump in modified current buffer")
  check(vim.api.nvim_win_get_cursor(0)[1], 3, "unsaved edit jump follows mark")
  vim.cmd.write()
  vim.cmd "bdelete"
  check(require("moonshine.jumper.store").new(path):load(), true, "unload flush")
  local reloaded = require("moonshine.jumper.store").new(path)
  assert(reloaded:load())
  check(reloaded.marks.p.row, 3, "persist after unload")
  file(b, { "B-one", "B-two" })
  local original = vim.api.nvim_get_current_buf()
  assert(jumper.jump "p")
  check(vim.api.nvim_buf_get_name(0), a, "jump opens A")
  check(vim.api.nvim_win_get_cursor(0)[1], 3, "jump follows edit")
  check(jumper.letters(vim.api.nvim_get_current_buf(), 3), "p", "mark letter after reopen")
  assert(jumper.set "q")
  file(b, { "B-one", "B-two" })
  assert(jumper.set "r")
  check(jumper.navigate(1), true, "traverse")
  check(vim.api.nvim_buf_get_name(0), a, "traversal wraps")
  check(jumper.navigate(1), true, "traverse to B")
  check(vim.api.nvim_buf_get_name(0), b, "forward opens B")
  check(jumper.navigate(-1), true, "reverse")
  check(vim.api.nvim_buf_get_name(0), a, "reverse opens A")
  assert(jumper.delete "r")
  check(jumper.get "r", nil, "delete named")
  file(b, { "B-one", "B-two" })
  jumper.delete_file()
  check(jumper.get "p" ~= nil, true, "delete file leaves A")
  vim.cmd.edit { args = { b } }
  local before = vim.api.nvim_get_current_buf()
  check(jumper.jump "r", false, "missing mark fails")
  check(vim.api.nvim_get_current_buf(), before, "missing mark stays")
  vim.fn.delete(a)
  check(jumper.jump "p", false, "missing file fails")
  check(vim.api.nvim_get_current_buf(), before, "missing file stays")
  check(vim.fn.filereadable(a), 0, "missing file not recreated")
  vim.cmd.enew()
  check(jumper.set "s", false, "unnamed buffer refused")
  file(b, { "first", "second", "third" })
  vim.api.nvim_win_set_cursor(0, { 3, 4 })
  assert(jumper.set "s")
  vim.cmd "bdelete"
  vim.fn.writefile({ "short" }, b)
  assert(jumper.jump "s")
  check(vim.api.nvim_win_get_cursor(0), { 1, 4 }, "external shortening clamps")
  check(jumper.get("s").row, 1, "clamped position persisted")
  check(jumper.add_next(), "t", "next letter after highest")
  assert(jumper.set("z"))
  check(jumper.add_next(), "a", "wrap after z")
  assert(jumper.delete_all())
  check(jumper.get("p"), nil, "delete all clears other files too")
  check(jumper.get("t"), nil, "delete all clears auto-added marks")
  for code = string.byte("a"), string.byte("z") do
    assert(jumper.set(string.char(code)))
  end
  check(jumper.add_next(), false, "all names occupied")
  check(jumper.get("a") ~= nil, true, "full namespace does not overwrite")
  assert(jumper.delete_all())
  local cleared = require("moonshine.jumper.store").new(path)
  assert(cleared:load())
  check(next(cleared.marks), nil, "delete all persisted")
  assert(original > 0)
end

mark_checks()
print "jumper checks passed"
