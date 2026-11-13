-- Run with: nvim --headless -u NONE -l tests/jumper_navigation.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/jumper.nvim")
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/utils")
vim.opt.rtp:prepend(vim.fn.getcwd())
package.loaded["integrations.notify"] = { replace = function() end }

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
local jumper = require "moonshine.jumper"
local repeat_navigation = require "moonshine.utils.navigation_repeat"
jumper.setup { path = root .. "/marks.json" }

local function current(name)
  assert(vim.api.nvim_buf_get_name(0) == root .. "/" .. name, "Expected file " .. name)
end

local function set_file(name, letters)
  local path = root .. "/" .. name
  vim.fn.writefile({ "one", "two", "three" }, path)
  vim.cmd.edit { args = { path } }
  for i, letter in ipairs(letters) do
    vim.api.nvim_win_set_cursor(0, { i, 0 })
    assert(jumper.set(letter))
  end
end

local warned = false
vim.notify = function()
  warned = true
end
assert(not jumper.navigate(1))
assert(warned, "Empty set should notify")

set_file("A", { "m", "n", "o" })
set_file("B", { "p", "q", "r" })
set_file("C", { "t", "u", "v" })
vim.cmd.enew()
assert(jumper.navigate(-1))
current "C"
assert(vim.api.nvim_win_get_cursor(0)[1] == 3, "no anchor starts from last")
assert(jumper.jump "o")
vim.cmd.edit { args = { root .. "/A" } }
vim.api.nvim_win_set_cursor(0, { 3, 0 })
assert(jumper.navigate(1))
current "B"
assert(vim.api.nvim_win_get_cursor(0)[1] == 1, "o -> p")
repeat_navigation.repeat_next()
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "repeat p -> q")
repeat_navigation.repeat_previous()
assert(vim.api.nvim_win_get_cursor(0)[1] == 1, "reverse q -> p")
assert(jumper.navigate(1, 3))
current "C"
assert(vim.api.nvim_win_get_cursor(0)[1] == 1, "count p -> t")
assert(jumper.jump "v")
assert(jumper.navigate(1))
current "A"
assert(vim.api.nvim_win_get_cursor(0)[1] == 1, "v -> m wrap")
assert(jumper.navigate(-1))
current "C"
assert(vim.api.nvim_win_get_cursor(0)[1] == 3, "m -> v reverse wrap")
jumper.delete_line()
assert(jumper.get("v") == nil, "delete line")
print "jumper navigation checks passed"
