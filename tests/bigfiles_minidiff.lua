-- nvim --headless -u NONE -i NONE -l tests/bigfiles_minidiff.lua
for _, feature in ipairs { "bigfiles", "mini_diff" } do
  vim.opt.rtp:append(vim.fn.getcwd() .. "/moonshine.nvim/" .. feature)
end
package.loaded["integrations.notify"] = { replace = function() end }
local diff = require "mini.diff"
local bigfiles = require "moonshine.bigfiles"
diff.setup {
  view = { style = "sign" },
  delay = { text_change = 10 },
  options = { linematch = 0 },
  mappings = {
    apply = "",
    reset = "",
    textobject = "",
    goto_first = "",
    goto_prev = "",
    goto_next = "",
    goto_last = "",
  },
}
local root = "/tmp/opencode/nvim-bigfiles-minidiff-" .. vim.uv.os_getpid()
vim.fn.mkdir(root, "p")
local function git(args)
  local result = vim
    .system(vim.list_extend({ "git", "-C", root }, args), { text = true })
    :wait()
  assert(result.code == 0, result.stderr)
end
local lines = {}
for i = 1, 11000 do
  lines[i] = "original line " .. i
end
local path = root .. "/large.txt"
vim.fn.writefile(lines, path)
git { "init", "-q" }
git { "add", "." }
git {
  "-c",
  "user.name=Test",
  "-c",
  "user.email=test@example.com",
  "commit",
  "-qm",
  "baseline",
}
lines[5] = "changed line"
vim.fn.writefile(lines, path)
vim.cmd("edit " .. vim.fn.fnameescape(path))
local buf = vim.api.nvim_get_current_buf()
assert(vim.b[buf].large_file and bigfiles.is_skipping(buf))
assert(vim.b[buf].minidiff_disable, "Large files must initially skip MiniDiff")

bigfiles.toggle(buf)
assert(not bigfiles.is_skipping(buf) and not vim.b[buf].minidiff_disable)
vim.api.nvim_exec_autocmds("BufEnter", { buffer = buf })
assert(
  not vim.b[buf].minidiff_disable,
  "BufEnter must respect the manual enable override"
)
assert(
  vim.wait(10000, function()
    local data = diff.get_buf_data(buf)
    return data and #data.hunks > 0
  end, 10),
  "Manually enabled large file must load Git hunks"
)

local other = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(other)
vim.api.nvim_set_current_buf(buf)
assert(not vim.b[buf].minidiff_disable, "Switching back must retain MiniDiff")
bigfiles.toggle(buf)
assert(bigfiles.is_skipping(buf) and vim.b[buf].minidiff_disable)
assert(diff.get_buf_data(buf) == nil, "Disabling must detach MiniDiff again")
bigfiles.toggle(buf)
assert(not vim.b[buf].minidiff_disable, "Repeated enable must work")

diff.disable(buf)
vim.cmd "enew!"
vim.fn.delete(root, "rf")
print "Big-file MiniDiff toggle checks passed"
vim.cmd "qa!"
