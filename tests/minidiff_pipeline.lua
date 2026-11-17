-- Run with: nvim --headless -u NONE -l tests/minidiff_pipeline.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/moonshine.nvim/mini_diff")
local diff = require "mini.diff"
local cache = require "mini.diff.hunks_cache"
local navigation = require "mini.diff.navigation.global_navigation"
local ranges =
  { { from = 2, to = 3 }, { from = 7, to = 7 }, { from = 12, to = 13 } }
assert(
  navigation.iterate(
    ranges,
    "next",
    { line_start = 2, n_times = 2, wrap = true }
  ) == 3,
  "counted forward movement"
)
assert(
  navigation.iterate(
    ranges,
    "prev",
    { line_start = 14, n_times = 2, wrap = true }
  ) == 2,
  "counted backward movement"
)
assert(
  navigation.iterate(
    ranges,
    "first",
    { line_start = 12, n_times = 1, wrap = false }
  ) == 1,
  "first range"
)
assert(
  navigation.iterate(
    ranges,
    "last",
    { line_start = 2, n_times = 1, wrap = false }
  ) == 3,
  "last range"
)
diff.setup {
  view = { style = "sign" },
  delay = { text_change = 10 },
  options = { wrap_goto = true, linematch = 0 },
}
local function equal(actual, expected, label)
  assert(vim.deep_equal(actual, expected), label .. ": " .. vim.inspect(actual))
end
local function hunk(from, count)
  return { buf_start = from, buf_count = count }
end
local segment_cases = {
  { {}, {}, {} },
  {
    {},
    { hunk(2, 2), hunk(4, 1) },
    { { from = 2, to = 4, layer = "staged" } },
  },
  {
    { hunk(2, 2), hunk(4, 1) },
    {},
    { { from = 2, to = 4, layer = "unstaged" } },
  },
  {
    { hunk(3, 1), hunk(4, 1) },
    { hunk(1, 6) },
    {
      { from = 1, to = 2, layer = "staged" },
      { from = 3, to = 4, layer = "unstaged" },
      { from = 5, to = 6, layer = "staged" },
    },
  },
  {
    { hunk(1, 6) },
    { hunk(2, 1), hunk(5, 1) },
    { { from = 1, to = 6, layer = "unstaged" } },
  },
  {
    { hunk(0, 0) },
    { hunk(0, 0) },
    { { from = 1, to = 1, layer = "unstaged" } },
  },
  {
    { hunk(4, 0) },
    { hunk(2, 3) },
    {
      { from = 2, to = 3, layer = "staged" },
      { from = 4, to = 4, layer = "unstaged" },
    },
  },
  {
    { hunk(2, 1) },
    { hunk(3, 1) },
    {
      { from = 2, to = 2, layer = "unstaged" },
      { from = 3, to = 3, layer = "staged" },
    },
  },
}
for index, case in ipairs(segment_cases) do
  local before = vim.deepcopy(case)
  equal(
    navigation.segments(case[1], case[2]),
    case[3],
    "layer segment case " .. index
  )
  equal(case, before, "segmentation never mutates source hunks")
end
local function wait(predicate, label)
  assert(vim.wait(4000, predicate, 10), label)
end
local root = "/tmp/opencode/minidiff-pipeline-" .. vim.fn.getpid()
assert(vim.fn.mkdir(root, "p") == 1)
local function git(...)
  local result = vim
    .system(vim.list_extend({ "git", "-C", root }, { ... }), { text = true })
    :wait()
  assert(result.code == 0, result.stderr)
end
git "init"
git("config", "user.email", "test@example.com")
git("config", "user.name", "Test")
vim.fn.writefile({ "old", "context", "third" }, root .. "/file.txt")
git("add", ".")
git("commit", "-m", "baseline")
vim.cmd.edit(root .. "/file.txt")
local buf = vim.api.nvim_get_current_buf()
local function ready()
  wait(function()
    local state, staged = diff.get_buf_state(buf), diff.get_staged_state(buf)
    return state
      and state.status == "ready"
      and staged
      and staged.status == "ready"
  end, "pipeline not ready")
end
ready()
local messages = {}
package.loaded["integrations.notify"] = {
  replace = function(_, _, message)
    messages[#messages + 1] = message
  end,
  send = function(_, message)
    messages[#messages + 1] = message
  end,
}
package.loaded["moonshine.diff.review"] = { setup = function() end }
package.loaded["moonshine.diff.history"] = { setup = function() end }
local integration = require "moonshine.diff"
equal(
  require "moonshine.diff.hunks",
  require "mini.diff.preview",
  "preview compatibility facade"
)

-- Saved and unsaved raw changes remain inspectable but net cancellation does
-- not create a marker, navigation stop, or statusline count.
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "saved" })
vim.cmd.write()
ready()
vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "old" })
ready()
equal(#cache.unstaged.get(buf).saved_hunks, 1, "raw saved layer")
equal(#cache.unsaved.get(buf).hunks, 1, "raw unsaved layer")
equal(#diff.get_buf_data(buf).hunks, 0, "effective cancellation")
equal(navigation.ranges(buf), {}, "cancelled layers have no navigation target")
equal(integration.lualine_hunks(), "", "cancelled layers have no count")
vim.cmd.redraw()
equal(
  #vim.api.nvim_buf_get_extmarks(
    buf,
    require("mini.diff.rendering").namespaces.viz,
    0,
    -1,
    {}
  ),
  0,
  "cancelled layers have no gutter marker"
)

vim.api.nvim_buf_set_lines(buf, 0, 1, false, { "unsaved" })
ready()
local before = navigation.ranges(buf)
vim.cmd.write()
ready()
equal(navigation.ranges(buf), before, "saving preserves effective locations")
equal(#cache.unsaved.get(buf).hunks, 0, "write refreshes saved baseline")
local snapshot = cache.unstaged.get(buf)
snapshot.hunks[1].buf_start = 99
snapshot.saved.text = "mutated"
equal(
  diff.get_buf_data(buf).hunks[1].buf_start,
  1,
  "snapshot mutation cannot alter engine"
)
assert(cache.unstaged.get(buf).saved.text ~= "mutated")

-- Kind stores are independent session singletons. Public publications reject
-- obsolete generations, changed buffers, changed saved files, and cleanup.
local other = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(other, root .. "/cache.txt")
vim.fn.writefile({ "one" }, root .. "/cache.txt")
local first = cache.staged.begin(other)
local second = cache.staged.begin(other)
assert(not cache.staged.publish(other, first, { status = "ready", hunks = {} }))
assert(
  cache.staged.publish(
    other,
    second,
    { status = "ready", hunks = { { buf_start = 2 } } }
  )
)
equal(cache.unstaged.get(other), nil, "kind store isolation")
equal(
  require("mini.diff.hunks_cache.staged").get(other).hunks[1].buf_start,
  2,
  "session singleton"
)
local changed = cache.unsaved.begin(
  other,
  { changedtick = vim.api.nvim_buf_get_changedtick(other) }
)
vim.api.nvim_buf_set_lines(other, 0, -1, false, { "changed" })
assert(
  not cache.unsaved.publish(other, changed, { status = "ready", hunks = {} })
)
local loader = require "mini.diff.hunks_loader"
local saved = cache.unsaved.begin(
  other,
  { saved_revision = loader.saved_revision(root .. "/cache.txt") }
)
vim.fn.writefile({ "a different saved size" }, root .. "/cache.txt")
assert(
  not cache.unsaved.publish(other, saved, { status = "ready", hunks = {} })
)
local renamed = cache.unsaved.begin(other)
vim.api.nvim_buf_set_name(other, root .. "/renamed.txt")
assert(
  not cache.unsaved.publish(other, renamed, { status = "ready", hunks = {} })
)
local cleared = cache.staged.begin(other)
cache.clear(other)
assert(
  not cache.staged.publish(other, cleared, { status = "ready", hunks = {} })
)

-- Toggle policy and renderer lifecycle are separate from snapshot loading.
local _, engine = debug.getupvalue(diff.enable, 1)
local obsolete_reference = cache.unstaged.begin(buf)
local previous_request = engine.git_cache[buf].request
engine.git_set_ref_text(buf)
wait(function()
  return engine.git_cache[buf].request > previous_request
end, "new reference generation")
assert(
  not cache.unstaged.publish(
    buf,
    obsolete_reference,
    { status = "ready", hunks = {} }
  )
)
ready()
local mode = require "mini.diff.hunk_mode"
mode.setup()
mode.setup()
equal(
  #vim.api.nvim_get_autocmds { group = "MiniDiffOverlayGlobal" },
  1,
  "mode setup is idempotent"
)
local preview = require "mini.diff.preview"
preview.setup()
local hooks = #vim.api.nvim_get_autocmds { group = "LargeHunkViewer" }
preview.setup()
equal(
  #vim.api.nvim_get_autocmds { group = "LargeHunkViewer" },
  hooks,
  "preview setup is idempotent"
)
local _, H = debug.getupvalue(diff.enable, 1)
local request = H.git_cache[buf].request
local original = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
mode.toggle()
ready()
assert(diff.get_buf_data(buf).overlay)
vim.cmd.redraw()
assert(
  #vim.api.nvim_buf_get_extmarks(buf, H.ns_id.overlay, 0, -1, {}) > 0,
  "inline overlay rendered"
)
mode.toggle()
ready()
vim.cmd.redraw()
equal(
  #vim.api.nvim_buf_get_extmarks(buf, H.ns_id.overlay, 0, -1, {}),
  0,
  "mode off clears inline overlays"
)
assert(
  #vim.api.nvim_buf_get_extmarks(buf, H.ns_id.viz, 0, -1, {}) > 0,
  "mode off preserves gutter markers"
)
equal(H.git_cache[buf].request, request, "mode toggle does not reread Git")
equal(
  vim.api.nvim_buf_get_lines(buf, 0, -1, false),
  original,
  "mode toggle preserves text"
)

-- A background buffer must render its own text, not the current window's text.
mode.toggle()
ready()
local background = vim.api.nvim_create_buf(true, false)
vim.b[background].minidiff_config = { source = diff.gen_source.none() }
diff.enable(background)
vim.api.nvim_buf_set_lines(background, 0, -1, false, { "background new" })
diff.set_ref_text(background, "background old\n")
diff.toggle_overlay(background)
wait(function()
  return diff.get_buf_state(background).status == "ready"
end, "background result")
equal(
  H.cache[background].overlay_lines[1][1].buf_line,
  "background new",
  "background overlay source"
)
diff.disable(background)
mode.toggle()
ready()

-- Global preference applies to a newly enabled buffer without changing cache
-- ownership or attaching disabled preview buffers.
mode.toggle()
ready()
local fresh = vim.api.nvim_create_buf(true, false)
vim.b[fresh].minidiff_config = { source = diff.gen_source.none() }
diff.enable(fresh)
diff.set_ref_text(fresh, "reference\n")
wait(function()
  return diff.get_buf_state(fresh).status == "ready"
    and diff.get_buf_data(fresh).overlay
end, "fresh buffer adopts overlay mode")
diff.disable(fresh)
mode.toggle()
ready()
integration.preview()
local preview_buf = vim.api.nvim_get_current_buf()
assert(
  vim.b[preview_buf].large_hunk_viewer
    and vim.bo[preview_buf].readonly
    and not vim.bo[preview_buf].modifiable
)
equal(diff.get_buf_data(preview_buf), nil, "preview remains detached")
equal(
  vim.api.nvim_buf_get_lines(preview_buf, 0, -1, false),
  { "old", "unsaved" },
  "preview content preserved"
)
assert(
  #vim.api.nvim_buf_get_extmarks(
      preview_buf,
      vim.api.nvim_create_namespace "LargeHunkViewer",
      0,
      -1,
      {}
    ) > 0
)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_delete(preview_buf, { force = true })

-- Switching source cannot leave staged/new-file targets in a manual review.
local painted = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(
  painted,
  0,
  -1,
  false,
  { "héllo world", "héllo Lua" }
)
require("mini.diff.rendering").paint_preview(
  painted,
  { "héllo world" },
  { "héllo Lua" }
)
local marks = vim.api.nvim_buf_get_extmarks(
  painted,
  vim.api.nvim_create_namespace "LargeHunkViewer",
  0,
  -1,
  { details = true }
)
local old_span, new_span = false, false
for _, mark in ipairs(marks) do
  if mark[4].priority == 20 then
    if mark[2] == 0 then
      old_span = mark[3] == 7 and mark[4].end_col == 12
    end
    if mark[2] == 1 then
      new_span = mark[3] == 7 and mark[4].end_col == 10
    end
  end
end
assert(old_span and new_span, "Unicode preview spans retain byte coordinates")
vim.api.nvim_buf_delete(painted, { force = true })
git("add", "file.txt")
wait(function()
  return diff.get_staged_data(buf).status == "ready"
    and #diff.get_staged_data(buf).hunks == 1
end, "staged snapshot")
diff.disable(buf)
vim.b[buf].minidiff_config = { source = diff.gen_source.none() }
diff.enable(buf)
diff.set_ref_text(buf, table.concat(original, "\n") .. "\n")
wait(function()
  return diff.get_buf_state(buf).status == "ready"
end, "manual source")
equal(
  navigation.ranges(buf),
  {},
  "source change clears obsolete kind snapshots"
)
diff.disable(buf)
cache.clear(other)
-- Moved review/history modules resolve from the merged runtime root. Their
-- existing picker/Git dependencies are stubbed, not their own implementations.
package.loaded["moonshine.git"] = {}
package.loaded["moonshine.utils.pretty_date"] = function()
  return "date"
end
package.loaded["telescope_pretty_picker"] = { preview = {} }
package.loaded["moonshine.diff.review"], package.loaded["moonshine.diff.history"] =
  nil, nil
require("moonshine.diff.review").setup()
require("moonshine.diff.history").setup()
for _, name in ipairs {
  "init",
  "hunks",
  "review",
  "history",
  "assure_git_hunks_are_ready",
} do
  local files =
    vim.api.nvim_get_runtime_file("lua/moonshine/diff/" .. name .. ".lua", true)
  equal(#files, 1, "single runtime owner: " .. name)
  assert(files[1]:find("/mini_diff/", 1, true))
end
vim.fn.delete(root, "rf")
print "minidiff pipeline: all checks passed"
