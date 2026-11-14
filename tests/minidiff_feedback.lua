-- Run with: nvim --headless -u NONE -l tests/minidiff_feedback.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/mini_diff")
local diff = require "mini.diff"
diff.setup { source = diff.gen_source.none(), delay = { text_change = 80 } }
local function check(actual, expected, label)
  assert(
    vim.deep_equal(actual, expected),
    label
      .. ": expected "
      .. vim.inspect(expected)
      .. ", got "
      .. vim.inspect(actual)
  )
end
local function state(buf, expected)
  check(diff.get_buf_state(buf).status, expected, "state")
end
local function wait_ready(buf)
  assert(
    vim.wait(1000, function()
      return diff.get_buf_state(buf).status == "ready"
    end),
    "did not become ready"
  )
end
local buf = vim.api.nvim_get_current_buf()
diff.enable(buf)
state(buf, "unavailable")
diff.set_ref_text(buf, "old\n")
state(buf, "loading")
wait_ready(buf)
assert(#diff.get_buf_data(buf).hunks > 0)
local snapshot = diff.get_buf_state(buf)
snapshot.status = "failed"
state(buf, "ready")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "old" })
state(buf, "updating")
wait_ready(buf)
check(#diff.get_buf_data(buf).hunks, 0, "clean is ready")
diff.disable(buf)
state(buf, "unavailable")

-- Inspect private seams only in tests to deterministically order reference IO.
local _, H = debug.getupvalue(diff.enable, 1)
if type(H) ~= "table" or H.cache == nil then
  for i = 1, 10 do
    local _, value = debug.getupvalue(diff.enable, i)
    if type(value) == "table" and value.cache then
      H = value
      break
    end
  end
end
assert(H.cache, "engine helpers not found")
diff.enable(buf)
diff.set_ref_text(buf, nil)
assert(vim.wait(1000, function()
  return diff.get_buf_state(buf).status == "unavailable"
end))
local real_diff = vim.diff
vim.diff = function()
  error "test computation failure"
end
diff.set_ref_text(buf, "old\n")
assert(vim.wait(1000, function()
  return diff.get_buf_state(buf).status == "failed"
end))
vim.diff = real_diff
diff.set_ref_text(buf, "old\n")
wait_ready(buf)
diff.disable(buf)

local root = vim.fn.tempname()
vim.fn.mkdir(root, "p")
local path = root .. "/file"
vim.fn.writefile({ "working" }, path)
vim.cmd.edit(path)
buf = vim.api.nvim_get_current_buf()
diff.disable(buf)
vim.b[buf].minidiff_config = { source = diff.gen_source.git() }
local read_reference, setup_watch =
  H.git_read_reference, H.git_setup_index_watch
local requests = {}
H.git_read_reference = function(args, cwd, callback)
  if args[1] == "diff" then
    callback(0, "")
    return
  end
  requests[#requests + 1] = callback
end
H.git_setup_index_watch = function() end
H.git_cache[buf] = nil
diff.enable(buf)
state(buf, "loading")
requests[1](1, "") -- Exhausted Git attachment is unavailable, not busy.
state(buf, "unavailable")
H.git_cache[buf] = nil
diff.enable(buf)
requests[2](0, root)
assert(vim.wait(1000, function()
  return #requests == 3
end))
requests[3](1, "") -- Missing index reference.
assert(vim.wait(1000, function()
  return diff.get_buf_state(buf).status == "unavailable"
end))
H.git_set_ref_text(buf)
assert(vim.wait(1000, function()
  return #requests == 4
end))
requests[4](0, "working\n")
wait_ready(buf)
H.git_set_ref_text(buf)
assert(vim.wait(1000, function()
  return #requests == 5
end))
requests[5](1, "", "Could not start Git: test")
state(buf, "failed")
H.git_set_ref_text(buf)
assert(vim.wait(1000, function()
  return #requests == 6
end))
requests[6](0, "working\n")
wait_ready(buf)

-- Newest read owns readiness even if buffer updates complete meanwhile.
H.git_set_ref_text(buf)
assert(vim.wait(1000, function()
  return #requests == 7
end))
H.git_set_ref_text(buf)
assert(vim.wait(1000, function()
  return #requests == 8
end))
requests[7](0, "obsolete\n")
state(buf, "updating")
check(diff.get_buf_data(buf).ref_text, "working\n", "obsolete read ignored")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "changed" })
vim.wait(150, function()
  return false
end)
state(buf, "updating")
requests[8](0, "newest\n")
wait_ready(buf)
check(diff.get_buf_data(buf).ref_text, "newest\n", "newest read accepted")
H.git_set_ref_text(buf)
assert(vim.wait(1000, function()
  return #requests == 9
end))
diff.disable(buf)
requests[9](0, "late\n")
check(diff.get_buf_data(buf), nil, "late read cannot re-enable")
H.git_cache[buf] = nil
diff.enable(buf)
local late_attach = requests[10]
diff.disable(buf)
H.git_cache[buf] = nil
diff.enable(buf)
late_attach(0, root)
state(buf, "loading")
requests[11](0, root)
assert(vim.wait(1000, function()
  return #requests == 12
end))
requests[12](0, "") -- Empty tracked files are valid references.
wait_ready(buf)
check(diff.get_buf_data(buf).ref_text, "", "empty reference")
diff.disable(buf)
H.git_read_reference, H.git_setup_index_watch = read_reference, setup_watch

-- Exercise actual process-launch failure, not only the callback classification.
local old_path, spawn_result = vim.env.PATH
vim.env.PATH = root
read_reference({ "show" }, root, function(_, _, err)
  spawn_result = err
end)
assert(vim.wait(1000, function()
  return spawn_result ~= nil
end))
vim.env.PATH = old_path
assert(spawn_result:find("Could not start Git", 1, true))

-- A rejecting source can fall back to the manual source and later recover.
vim.b[buf].minidiff_config = {
  source = {
    {
      attach = function()
        return false
      end,
    },
    diff.gen_source.none(),
  },
}
diff.enable(buf)
state(buf, "unavailable")
diff.set_ref_text(buf, "changed\n")
wait_ready(buf)
vim.api.nvim_buf_delete(buf, { force = true })
assert(H.cache[buf] == nil)
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/diff_tools")
local messages = {}
package.loaded["integrations.notify"] = {
  replace = function(key, title, message, level)
    messages[#messages + 1] = { key, title, message, level }
  end,
  send = function(title, message, level)
    messages[#messages + 1] = { "send", title, message, level }
  end,
}
package.loaded["moonshine.diff.review"] = { setup = function() end }
package.loaded["moonshine.diff.history"] = { setup = function() end }
local integration = require "moonshine.diff"
local feedback = require "moonshine.diff.assure_git_hunks_are_ready"
buf = vim.api.nvim_get_current_buf()
vim.b[buf].minidiff_config = { source = diff.gen_source.none() }
diff.enable(buf)
local actions = {
  integration.nav,
  integration.preview,
  integration.select,
  integration.reset_hunk,
  integration.reset_buffer,
}
local function blocked(expected)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  for _, action in ipairs(actions) do
    action(-1)
    assert(
      messages[#messages][3]:find(expected, 1, true),
      messages[#messages][3]
    )
    check(
      vim.api.nvim_buf_get_lines(buf, 0, -1, false),
      lines,
      "blocked action preserves text"
    )
  end
end
blocked "unavailable"
diff.set_ref_text(buf, "reference\n")
blocked "loading"
wait_ready(buf)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "edited", "context" })
blocked "updating"
wait_ready(buf)
check(
  vim.api.nvim_buf_get_lines(buf, 0, -1, false),
  { "edited", "context" },
  "no deferred reset"
)
vim.diff = function()
  error "computation failed"
end
diff.set_ref_text(buf, "reference\n")
assert(vim.wait(1000, function()
  return diff.get_buf_state(buf).status == "failed"
end))
blocked "failed"
vim.diff = real_diff
diff.set_ref_text(buf, "edited\ncontext\n")
wait_ready(buf)
blocked "No changes"
diff.set_ref_text(buf, "old\ncontext\n")
wait_ready(buf)
vim.api.nvim_win_set_cursor(0, { 2, 0 })
integration.preview()
assert(messages[#messages][3]:find("No hunk under cursor", 1, true))
integration.reset_hunk()
assert(messages[#messages][3]:find("No hunk under cursor", 1, true))
feedback.message(buf, "first")
local key = messages[#messages][1]
feedback.message(buf, "second")
check(messages[#messages][1], key, "same buffer replacement key")
local other = vim.api.nvim_create_buf(true, false)
feedback.message(other, "other")
assert(messages[#messages][1] ~= key, "buffers need separate notification keys")
local do_hunks = diff.do_hunks
diff.do_hunks = function()
  error "reset failed test"
end
integration.reset_buffer()
assert(messages[#messages][3]:find("reset failed test", 1, true))
check(messages[#messages][4], vim.log.levels.ERROR, "operation failure level")
diff.do_hunks = do_hunks
local count = #messages
diff.set_ref_text(buf, "edited\ncontext\n")
wait_ready(buf)
check(#messages, count, "no unsolicited notifications")
local refreshes = 0
package.loaded.lualine = {
  refresh = function()
    refreshes = refreshes + 1
  end,
}
check(integration.lualine_hunks(), "", "clean statusline")
diff.set_ref_text(buf, "old\ncontext\n")
check(integration.lualine_hunks(), "diff: updating…", "pending statusline")
vim.api.nvim_set_current_buf(other)
check(integration.lualine_hunks(), "", "other buffer statusline")
vim.api.nvim_set_current_buf(buf)
wait_ready(buf)
assert(integration.lualine_hunks():find("hunks:", 1, true))
assert(
  vim.wait(1000, function()
    return refreshes > 0
  end),
  "state event refresh"
)
local refresh_count = refreshes
integration.lualine_hunks()
integration.lualine_hunks()
check(refreshes, refresh_count, "render has no side effects")
vim.api.nvim_set_current_buf(other)
diff.disable(other)
vim.b[other].minidiff_config = { source = diff.gen_source.none() }
diff.enable(other)
diff.set_ref_text(other, "old\n")
check(integration.lualine_hunks(), "diff: loading…", "initial statusline")
wait_ready(other)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_win_set_cursor(0, { 1, 0 })
local original_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
vim.b[buf].minidiff_review = true
integration.reset_hunk()
integration.reset_buffer()
check(
  vim.api.nvim_buf_get_lines(buf, 0, -1, false),
  original_lines,
  "review reset protection"
)
local focused = false
package.loaded["moonshine.diff.review"].focus_list = function()
  focused = true
end
integration.nav(1)
assert(focused, "last review hunk focuses list")
vim.b[buf].minidiff_review = nil
local neotree = false
package.loaded["moonshine.utils.ui_prevent_mess"] = function() end
package.loaded["moonshine.utils.focus_neotree"] = function(source)
  neotree = source == "git_status"
end
integration.nav(1)
assert(neotree, "last working hunk focuses Neo-tree")

-- Preview still opens its locked hunk buffer, then reset uses current hunks.
integration.preview()
assert(vim.b.large_hunk_viewer and vim.bo.readonly and not vim.bo.modifiable)
local preview = vim.api.nvim_get_current_buf()
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_delete(preview, { force = true })
local selected, textobject = false, diff.textobject
diff.textobject = function()
  selected = true
end
integration.select()
assert(selected, "ready selection reaches textobject")
diff.textobject = textobject
integration.reset_hunk()
wait_ready(buf)
check(
  vim.api.nvim_buf_get_lines(buf, 0, -1, false),
  { "old", "context" },
  "ready reset hunk"
)
check(integration.lualine_hunks(), "", "clean after reset")
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "again" })
wait_ready(buf)
integration.reset_buffer()
wait_ready(buf)
check(
  vim.api.nvim_buf_get_lines(buf, 0, -1, false),
  { "old", "context" },
  "ready reset buffer"
)
integration.toggle_overlay()
assert(vim.g.minidiff_overlay)
assert(vim.wait(1000, function()
  return diff.get_buf_data(buf).overlay
end))
integration.toggle_overlay()
assert(not vim.g.minidiff_overlay)
assert(vim.wait(1000, function()
  return not diff.get_buf_data(buf).overlay
end))
wait_ready(buf)

-- Native diff-window navigation must bypass an unavailable MiniDiff state.
diff.disable(buf)
vim.cmd "diffthis"
vim.cmd "vnew"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "different" })
vim.cmd "diffthis"
count = #messages
integration.nav(1)
check(#messages, count, "native diff navigation bypasses guard")
vim.cmd "diffoff!"
vim.cmd "close!"
vim.api.nvim_set_current_buf(buf)
print "minidiff feedback: all checks passed"
