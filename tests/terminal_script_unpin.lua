-- nvim --headless -u NONE -l tests/terminal_script_unpin.lua
for _, feature in ipairs { "buffers", "terminal_reimagined", "utils" } do
  vim.opt.rtp:append(vim.fn.getcwd() .. "/moonshine.nvim/" .. feature)
end
package.loaded.lualine = { refresh = function() end }
local terminal = require "terminal_reimagined"
local buffers = require "moonshine.buffers"
local root = "/tmp/opencode/nvim-script-unpin-" .. vim.uv.os_getpid()
vim.fn.mkdir(root, "p")
local regular = vim.api.nvim_get_current_buf()
local jobs = {}
local function wait_for(predicate)
  assert(vim.wait(10000, predicate, 10), "Timed out waiting for script")
end
local function run(name, lines, interpreter)
  local path = root .. "/" .. name
  vim.fn.writefile(lines, path)
  assert(terminal.run_script(path, interpreter))
  local buf = vim.api.nvim_get_current_buf()
  jobs[#jobs + 1] = vim.b[buf].terminal_job_id
  assert(buffers.is_pinned(buf), "Script terminal must start pinned")
  return buf
end
local held = run("held script.sh", {
  "printf 'SCRIPT_READY\\n'",
  "IFS= read -r answer",
  "exit 7",
}, "bash")
wait_for(function()
  local text =
    table.concat(vim.api.nvim_buf_get_lines(held, 0, -1, false), "\n")
  return text:find("SCRIPT_READY", 1, true) ~= nil
end)
assert(buffers.is_pinned(held), "Running script must remain pinned")
vim.api.nvim_exec_autocmds("TermRequest", {
  buffer = held,
  data = { sequence = "\027]7;file://localhost/tmp" },
})
assert(buffers.is_pinned(held), "Unrelated terminal requests must not unpin")
vim.api.nvim_set_current_buf(regular)
vim.api.nvim_chan_send(vim.b[held].terminal_job_id, "done\n")
wait_for(function()
  return not buffers.is_pinned(held)
end)
assert(
  vim.api.nvim_get_current_buf() == regular,
  "Completion must not steal focus"
)
assert(
  vim.fn.jobwait({ vim.b[held].terminal_job_id }, 0)[1] == -1,
  "Script completion must keep its shell running"
)

for _, case in ipairs {
  { "fast.sh", { "exit 0" }, "bash" },
  { "fast.py", { "raise SystemExit(3)" }, "python3" },
} do
  local buf = run(case[1], case[2], case[3])
  wait_for(function()
    return not buffers.is_pinned(buf)
  end)
end

assert(terminal.open_new())
local normal = vim.api.nvim_get_current_buf()
jobs[#jobs + 1] = vim.b[normal].terminal_job_id
assert(buffers.is_pinned(normal), "Ordinary terminals must remain pinned")

-- A shell dying before it emits the completion request must also release pin.
local closed = run("closed.sh", { 'kill -TERM "$PPID"' }, "bash")
wait_for(function()
  return not buffers.is_pinned(closed)
end)
for _, job in ipairs(jobs) do
  pcall(vim.fn.jobstop, job)
end
vim.fn.delete(root, "rf")
print "Script terminal unpin checks passed"
vim.cmd "qa!"
