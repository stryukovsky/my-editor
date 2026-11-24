-- nvim --headless -u NONE -i NONE -l tests/native_completion_loading.lua
vim.opt.rtp:append(
  vim.fn.glob(vim.fn.getcwd() .. "/moonshine.nvim/*", true, true)
)
local loading = require "native_completion.loading"
local ranking = require "native_completion"
local snapshot = {
  line = "item",
  row = 0,
  col = 4,
  keyword = "item",
  clients = {},
  single_client = true,
  context = { kind = "unknown", spans = {} },
}
local client = { id = 1, offset_encoding = "utf-16" }
local items = {}
for i = 10000, 1, -1 do
  items[#items + 1] = { label = "item" .. i, sortText = ("%05d"):format(i) }
end
items[#items + 1] = { label = "unrelated", sortText = "0" }
local response = {
  items = items,
  itemDefaults = { insertTextFormat = 2 },
  isIncomplete = false,
}
local selected, heartbeat = nil, 0
local timer = vim.uv.new_timer()
timer:start(0, 1, function()
  heartbeat = heartbeat + 1
end)
loading.select(response, client, snapshot, function()
  return true
end, function(result)
  selected = result
end)
assert(not selected, "large response must not process inline")
assert(
  vim.wait(10000, function()
    return selected ~= nil
  end, 1),
  "selection finishes"
)
timer:stop()
timer:close()
assert(heartbeat > 1, "event loop runs while loading")
assert(#selected.items == 200, "native popup work bounded")
assert(selected.itemDefaults == response.itemDefaults, "defaults retained")
assert(selected.isIncomplete, "subset requests fresh results after input")
assert(
  #response.items == 10001 and not response.isIncomplete,
  "response unmodified"
)
local candidates = {}
for _, item in ipairs(items) do
  if item.label ~= "unrelated" then
    candidates[#candidates + 1] = {
      word = item.label,
      user_data = { nvim = { lsp = { completion_item = item, client_id = 1 } } },
    }
  end
end
table.sort(candidates, ranking.comparator(vim.deepcopy(snapshot)))
local expected = {}
for i = 1, 200 do
  expected[candidates[i].word] = true
end
for _, item in ipairs(selected.items) do
  assert(
    expected[item.label],
    "heap agrees with complete ranking: " .. item.label
  )
end
local active, called = true, false
loading.select(response, client, snapshot, function()
  return active
end, function()
  called = true
end)
vim.defer_fn(function()
  active = false
end, 2)
vim.wait(100, function()
  return called
end, 1)
assert(not called, "obsolete work never reaches native callback")
local small = { items = { items[1] } }
loading.select(small, client, snapshot, function()
  return true
end, function(result)
  assert(result == small, "small responses unchanged")
end)
local original_get = vim.lsp.completion.get
local request = function() end
client.request = request
vim.lsp.completion.get = function()
  assert(client.request ~= request, "interception active only while sending")
  error "fixture failure"
end
assert(not pcall(loading.get, { client }, snapshot, function()
  return true
end))
assert(client.request == request, "request restored even after errors")
vim.lsp.completion.get = original_get
print(
  ("PASS batched loading, top-200 ranking, cancellation, defaults, restoration; %d heartbeats"):format(
    heartbeat
  )
)
vim.cmd "qa!"
