-- nvim --headless -u NONE -i NONE -l tests/csv_render.lua [config-root]
local root = arg[1] or vim.fn.getcwd()
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(root .. "/moonshine.nvim/csv-render")
vim.opt.rtp:append(root .. "/data/lazy/langmapper.nvim")
local parser = require "moonshine.csv_render.parser"
local render = require "moonshine.csv_render.render"
local preview = require "moonshine.csv_render"
local opts = { fit_columns = 10, min_column_width = 4, max_column_width = 40 }
local checks = 0
local function eq(actual, expected)
  checks = checks + 1
  assert(
    vim.deep_equal(actual, expected),
    vim.inspect(actual) .. " ~= " .. vim.inspect(expected)
  )
end
local function wait_for(fn)
  assert(vim.wait(10000, fn, 10), "timed out waiting for CSV preview")
end
local function text(buf)
  return vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false)
end
local records = parser.parse({
  "id,name,note,empty",
  '1,"with, comma","a ""quote""",',
  '2,Ж中文,"first',
  'second",end',
}, ",")
eq(records[2].cells, { "1", "with, comma", 'a "quote"', "" })
eq(records[3].cells, { "2", "Ж中文", "first\nsecond", "end" })
eq(records[3].first, 3)
eq(records[3].last, 4)
eq(records[3].positions[4], { 4, 8 })
eq(parser.parse({ "\239\187\191a,b\r", ',""\r' }, ",")[1].cells, { "a", "b" })
eq(parser.parse({ "\239\187\191a,b" }, ",")[1].positions[1], { 1, 3 })
eq(parser.delimiter({ '"name;still name";value' }, "csv"), ";")
eq(parser.delimiter({ "a\tb" }, "tsv"), "\t")
eq(parser.parse({ "a\tb", "\t" }, "\t")[2].cells, { "", "" })
eq(pcall(parser.parse, { 'a,"unfinished' }, ","), false)
eq(pcall(parser.parse, { 'a,"closed"oops' }, ","), false)
eq(render.wrap("some text long", 5), { "some ", "text ", "long" })
eq(render.wrap("ééé中文😀", 4), { "ééé", "中文", "😀" })
eq(
  table.concat(render.wrap(string.rep("abcd", 20000), 9)),
  string.rep("abcd", 20000)
)
local doc = render.build(records, 80, opts)
for _, line in ipairs(doc.lines) do
  eq(vim.fn.strdisplaywidth(line), 77)
end
local wide = {}
for col = 1, 64 do
  wide[col] = "column " .. col
end
local large_doc = render.build({ { cells = wide } }, 80, opts)
assert(vim.fn.strdisplaywidth(large_doc.lines[1]) > 80)
local ten = {}
for col = 1, 10 do
  ten[col] = string.rep("cell ", 30)
end
local ten_doc = render.build({ { cells = ten } }, 120, opts)
for _, line in ipairs(ten_doc.lines) do
  eq(vim.fn.strdisplaywidth(line), 111)
end
local heading_doc = render.build({
  { cells = { string.rep("中", 120) } },
  { cells = { string.rep("中", 120) } },
}, 20, opts)
eq(#heading_doc.headers, 5)
assert(heading_doc.lines[6]:find("...", 1, true))
assert(#heading_doc.lines > 20, "data cells must retain their full content")
for _, line in ipairs(heading_doc.lines) do
  eq(vim.fn.strdisplaywidth(line), 20)
end

require "mappings.csv"
vim.o.hidden = false
vim.o.columns = 100
vim.wo.wrap = true
vim.wo.number = true
local source = vim.api.nvim_create_buf(true, false)
vim.api.nvim_set_current_buf(source)
vim.bo[source].filetype = "csv"
local source_lines =
  { "id,name,note", '1,Ж中文,"first', 'second"', "2,hello,done" }
vim.api.nvim_buf_set_lines(source, 0, -1, false, source_lines)
vim.api.nvim_win_set_cursor(0, { 4, 2 })
local undo = vim.fn.undotree()
local modified = vim.bo[source].modified
local mapping = vim.fn.maparg("<A-i>", "n", false, true)
eq(mapping.desc, "CSV table preview")
mapping.callback()
local dst = vim.api.nvim_get_current_buf()
assert(dst ~= source)
wait_for(function()
  return text(dst)[1]:sub(1, #"┌") == "┌"
end)
eq(vim.bo[dst].modifiable, false)
eq(vim.bo[dst].readonly, true)
eq(vim.wo.wrap, false)
assert(text(dst)[vim.api.nvim_win_get_cursor(0)[1]]:find("hello", 1, true))
eq(text(source), source_lines)
-- Source edits from another window/API refresh the same preview.
vim.api.nvim_buf_set_lines(source, 3, 4, false, { "2,updated,done" })
wait_for(function()
  return table.concat(text(dst), "\n"):find("updated", 1, true) ~= nil
end)
vim.fn.maparg("<A-i>", "n", false, true).callback()
eq(vim.api.nvim_get_current_buf(), source)
eq(vim.api.nvim_win_get_cursor(0)[1], 4)
eq(vim.wo.wrap, true)
eq(vim.wo.number, true)
eq(vim.bo[source].modified, modified)
-- Preview-only round trips preserve the source undo tree exactly.
undo = vim.fn.undotree()
undo.synced = nil -- Leaving any buffer synchronizes its current undo block.
preview.toggle()
wait_for(function()
  return text()[1]:sub(1, #"┌") == "┌"
end)
preview.toggle()
local after = vim.fn.undotree()
after.synced = nil
eq(after, undo)
eq(text(), { "id,name,note", '1,Ж中文,"first', 'second"', "2,updated,done" })
-- Cancellation, including a preview closed before its first rendering step.
preview.toggle()
preview.toggle()
vim.wait(150, function()
  return false
end)
eq(vim.api.nvim_get_current_buf(), source)
eq(vim.wo.wrap, true)

-- Wiping a preview or its source releases listeners and cancels pending work.
preview.toggle()
local wiped = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_delete(wiped, { force = true })
vim.api.nvim_set_current_buf(source)
preview.toggle()
wait_for(function()
  return text()[1]:sub(1, #"┌") == "┌"
end)
preview.toggle()
eq(vim.api.nvim_get_current_buf(), source)
local disposable = vim.api.nvim_create_buf(true, false)
vim.o.hidden = true
vim.api.nvim_set_current_buf(disposable)
vim.api.nvim_buf_set_lines(disposable, 0, -1, false, { "a,b", "c,d" })
preview.toggle()
local orphan = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_delete(disposable, { force = true })
wait_for(function()
  return not vim.api.nvim_buf_is_valid(orphan)
end)
vim.api.nvim_set_current_buf(source)

-- Exercise the real stress fixture without loading any external CSV plugin.
if vim.fn.filereadable(root .. "/large-test.csv") == 1 then
  vim.api.nvim_buf_set_lines(
    source,
    0,
    -1,
    false,
    vim.fn.readfile(root .. "/large-test.csv")
  )
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  local start = vim.uv.hrtime()
  preview.toggle()
  local ticks = 0
  local timer = vim.uv.new_timer()
  timer:start(1, 1, function()
    ticks = ticks + 1
  end)
  wait_for(function()
    return text()[1]:sub(1, #"┌") == "┌"
  end)
  timer:stop()
  timer:close()
  assert(ticks > 10, "rendering blocked the event loop")
  assert(vim.fn.strdisplaywidth(text()[1]) > vim.o.columns)
  eq(vim.wo.wrap, false)
  print(
    string.format(
      "Large CSV: %.2fs, %d rendered lines, %d event-loop ticks",
      (vim.uv.hrtime() - start) / 1e9,
      vim.api.nvim_buf_line_count(0),
      ticks
    )
  )
  preview.toggle()
end
assert(not package.loaded.csvview)
print(
  "PASS: "
    .. checks
    .. " CSV parser, rendering, mapping, lifecycle and source-preservation checks"
)
vim.cmd "qa!"
