local M = {}
local ranking = require "native_completion"
local base = require "native_completion.base"

-- Bound native conversion, sorting and complete() as well as our own work.
-- A narrower query searches the full server response again.
local limit = 200

function M.select(result, client, snapshot, valid, done)
  local items = type(result) == "table" and (result.items or result)
  if type(items) ~= "table" or #items <= limit then
    if valid() then
      done(result)
    end
    return
  end
  local compare = ranking.comparator(vim.tbl_extend("force", {}, snapshot))
  local heap, index = {}, 1
  local defaults = result.itemDefaults or {}
  local function candidate(item)
    -- Defaults remain on the response for native conversion/acceptance. Only
    -- project its range here so ranking uses the same replacement prefix.
    local projected = item
    if defaults.editRange and not item.textEdit then
      projected = setmetatable({
        textEdit = {
          range = defaults.editRange.start and defaults.editRange or nil,
          insert = defaults.editRange.insert,
          replace = defaults.editRange.replace,
        },
      }, { __index = item })
    end
    local query = base.get(snapshot, projected, client)
    local server_filtered = projected.textEdit
      and not projected.textEdit.newText
      and not defaults.editRange
    if
      query
      and query:find "%w"
      and not (server_filtered and not item.filterText)
    then
      local text = item.filterText or item.label or ""
      if #vim.fn.matchfuzzy({ text }, query) == 0 then
        return
      end
    end
    return {
      word = item.label,
      original = item,
      user_data = {
        nvim = { lsp = { completion_item = projected, client_id = client.id } },
      },
    }
  end
  -- Worst-first heap: O(n log limit), with no whole-response sort.
  local function push(value)
    if #heap < limit then
      local pos = #heap + 1
      heap[pos] = value
      while pos > 1 do
        local parent = math.floor(pos / 2)
        if not compare(heap[parent], heap[pos]) then
          break
        end
        heap[parent], heap[pos] = heap[pos], heap[parent]
        pos = parent
      end
    elseif compare(value, heap[1]) then
      heap[1] = value
      local pos = 1
      while pos * 2 <= #heap do
        local child = pos * 2
        if child < #heap and compare(heap[child], heap[child + 1]) then
          child = child + 1
        end
        if not compare(heap[pos], heap[child]) then
          break
        end
        heap[pos], heap[child] = heap[child], heap[pos]
        pos = child
      end
    end
  end
  local function step()
    if not valid() then
      return
    end
    local deadline = vim.uv.hrtime() + 3e6
    repeat
      local value = candidate(items[index])
      if value then
        push(value)
      end
      index = index + 1
    until index > #items or vim.uv.hrtime() >= deadline
    if index <= #items then
      vim.defer_fn(step, 1)
      return
    end
    local selected = {}
    for i, value in ipairs(heap) do
      selected[i] = value.original
    end
    if result.items then
      local response = vim.tbl_extend("force", {}, result)
      response.items = selected
      -- The popup contains a subset: request again when the query changes.
      response.isIncomplete = true
      done(response)
    else
      done { items = selected, isIncomplete = true }
    end
  end
  vim.defer_fn(step, 1)
end

-- Intercept only requests issued by this invocation; leave the native request
-- lifecycle, resolver, snippets and CompleteDone context in Neovim's ownership.
function M.get(clients, snapshot, valid)
  local originals = {}
  for _, client in ipairs(clients) do
    local request = client.request
    originals[client] = request
    client.request = function(self, method, params, callback, ...)
      if method == "textDocument/completion" then
        local native_callback = callback
        callback = function(err, result, ctx, config)
          M.select(result, self, snapshot, valid, function(selected)
            native_callback(err, selected, ctx, config)
          end)
        end
      end
      return request(self, method, params, callback, ...)
    end
  end
  local ok, err = pcall(vim.lsp.completion.get)
  for client, request in pairs(originals) do
    client.request = request
  end
  if not ok then
    error(err)
  end
end

return M
