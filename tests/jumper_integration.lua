-- Run with: nvim --headless '+luafile tests/jumper_integration.lua' +qa
local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
local jumper = require "moonshine.jumper"
jumper.setup { path = root .. "/marks.json" }
local path = root .. "/A"
vim.fn.writefile({ "one", "two", "three" }, path)
vim.cmd.edit { args = { path } }

local function keys(sequence)
  vim.cmd.normal { args = { sequence }, bang = false }
end

assert(vim.fn.maparg("mp", "n") ~= "", "lowercase setter mapping")
assert(vim.fn.maparg("'p", "n") ~= "", "lowercase jump mapping")
assert(vim.fn.maparg("mA", "n") == "", "native uppercase setter")
assert(vim.fn.maparg("''", "n") == "", "native previous-position jump")
keys "mA"
assert(vim.fn.getpos("'A")[2] == 1, "native uppercase mark still works")
vim.api.nvim_win_set_cursor(0, { 2, 0 })
keys "mp"
assert(jumper.get("p").row == 2, "mapped setter")
local statuscolumn = vim.api.nvim_eval_statusline(vim.wo.statuscolumn, {
  winid = vim.api.nvim_get_current_win(),
  use_statuscol_lnum = 2,
  maxwidth = 120,
}).str
assert(statuscolumn:find("p", 1, true), "mark rendered in status column: " .. statuscolumn)
vim.wo.signcolumn = "yes:3"
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace "MiniDiffViz", 1, 0, {
  sign_text = "D",
  sign_hl_group = "DiffAdd",
})
vim.api.nvim_buf_set_extmark(buf, vim.api.nvim_create_namespace "jumper-test-diagnostic", 1, 0, {
  sign_text = "E",
  sign_hl_group = "DiagnosticSignError",
})
vim.cmd.redraw()
vim.wait(100, function()
  return false
end)
statuscolumn = vim.api.nvim_eval_statusline(vim.wo.statuscolumn, {
  winid = vim.api.nvim_get_current_win(),
  use_statuscol_lnum = 2,
  maxwidth = 120,
}).str
assert(statuscolumn:find("D", 1, true), "diff sign retained: " .. statuscolumn)
assert(statuscolumn:find("E", 1, true), "other sign retained: " .. statuscolumn)
assert(statuscolumn:find("p", 1, true), "mark retained beside signs: " .. statuscolumn)
vim.wo.foldmethod = "manual"
vim.cmd "1,2fold"
assert(vim.fn.foldclosed(1) == 1, "fold remains functional beside mark segment")
vim.cmd "normal! zo"
vim.api.nvim_win_set_cursor(0, { 1, 0 })
keys "'p"
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "mapped jump")
keys "mq"
keys "[m"
assert(vim.api.nvim_win_get_cursor(0)[1] == 2, "mapped reverse")
keys "]]"
assert(jumper.get("q") ~= nil, "repeat mapping installed")
assert(vim.fn.maparg(";", "n") ~= "", "shared repeat mapping")
assert(vim.fn.maparg("n", "n") ~= "", "shared n repeat mapping")
assert(vim.fn.maparg("N", "n") ~= "", "shared N repeat mapping")
assert(vim.fn.maparg("<A-;>", "n") ~= "", "shared reverse repeat mapping")
vim.cmd "JumperDelete p"
assert(jumper.get("p") == nil, "named deletion command")
assert(vim.fn.maparg("<leader>maa", "n") ~= "", "auto-add mapping")
assert(vim.fn.maparg("<leader>mad", "n") ~= "", "delete-all mapping")
keys " maa"
assert(jumper.get("r") ~= nil, "mapped auto-add after q assigns r")
keys " mad"
assert(jumper.get("q") == nil and jumper.get("r") == nil, "mapped delete-all clears namespace")
vim.cmd.enew()
vim.bo.buftype = "nofile"
vim.bo.modifiable = false
vim.api.nvim_exec_autocmds("BufWinEnter", { buffer = 0 })
assert(vim.wait(1000, function()
  return vim.wo.statuscolumn == "" and vim.wo.foldcolumn == "0" and vim.wo.signcolumn == "no"
end), "technical buffer gutter hidden")
print "jumper mappings checks passed"
