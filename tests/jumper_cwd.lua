-- nvim --headless -u NONE -i NONE -l tests/jumper_cwd.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/jumper.nvim")
local base = "/tmp/opencode/jumper-cwd-" .. vim.uv.os_getpid()
local one, two = base .. "/one", base .. "/two"
vim.fn.mkdir(one, "p")
vim.fn.mkdir(two, "p")
local first, second = one .. "/first.py", two .. "/second.py"
vim.fn.writefile({ "first", "second" }, first)
vim.fn.writefile({ "other", "line" }, second)
local path = base .. "/marks-scoped.json"
local legacy_path = base .. "/marks.json"
local legacy = vim.json.encode {
  version = 1,
  marks = { b = { path = first, row = 2, col = 0 } },
}
vim.fn.writefile({ legacy }, legacy_path)

local jumper = require "moonshine.jumper"
vim.cmd.cd(one)
jumper.setup { path = path, legacy_path = legacy_path }
assert(jumper.get("b").path == first, "legacy mark not visible inside its cwd")
assert(vim.fn.filereadable(path) == 0, "reading legacy marks must not create the scoped store")
vim.cmd.edit(first)
local first_buf = vim.api.nvim_get_current_buf()
assert(jumper.letters(0, 2) == "b", "legacy gutter mark missing")
vim.api.nvim_win_set_cursor(0, { 1, 0 })
assert(jumper.set("a"))

vim.cmd.cd(two)
assert(jumper.get("a") == nil and jumper.get("b") == nil, "marks leaked to another cwd")
assert(jumper.letters(first_buf, 2) == "", "old cwd gutter mark remained visible")
local namespace = vim.api.nvim_get_namespaces()["moonshine.jumper.positions"]
assert(#vim.api.nvim_buf_get_extmarks(first_buf, namespace, 0, -1, {}) == 0, "old cwd extmarks were not cleared")
vim.cmd.edit(second)
assert(jumper.letters(0, 2) == "", "old cwd mark leaked into the gutter")
vim.api.nvim_win_set_cursor(0, { 2, 0 })
assert(jumper.set("a"))
assert(jumper.jump("a") and vim.api.nvim_buf_get_name(0) == second)
vim.cmd.cd(one)
assert(jumper.get("a").path == first and jumper.get("b").path == first, "switching cwd lost project marks")
assert(jumper.jump("a") and vim.api.nvim_buf_get_name(0) == first)
assert(jumper.delete("b"), "legacy mark could not be hidden in this cwd")
assert(jumper.get("b") == nil)
vim.cmd.cd(two)
assert(jumper.get("a").path == second and jumper.get("b") == nil, "deletion affected another cwd")

assert(vim.fn.readfile(legacy_path)[1] == legacy, "original v1 file changed")
local stored = vim.json.decode(vim.fn.readfile(path)[1])
assert(stored.version == 2 and stored.workspaces[one].a.path == first and stored.workspaces[two].a.path == second)
jumper.setup { path = path, legacy_path = legacy_path }
assert(jumper.get("a").path == second, "scoped marks did not survive restart")
vim.cmd.cd(one)
assert(jumper.get("a").path == first and jumper.get("b") == nil, "legacy tombstone did not survive restart")
print "jumper cwd checks passed"
