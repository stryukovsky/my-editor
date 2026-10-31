local M = {}
local api = vim.api
local base = require "native_completion.base"
local context = require "native_completion.context"
local snapshot
local sorting
local generation = 0

function M.invalidate()
  generation = generation + 1
  snapshot = nil
  sorting = nil
end

local function state()
  local cursor = api.nvim_win_get_cursor(0)
  return {
    buf = api.nvim_get_current_buf(),
    tick = api.nvim_buf_get_changedtick(0),
    row = cursor[1] - 1,
    col = cursor[2],
    line = api.nvim_get_current_line(),
    generation = generation,
  }
end

local function same(a, b)
  return a
    and a.buf == b.buf
    and a.tick == b.tick
    and a.row == b.row
    and a.col == b.col
    and a.generation == b.generation
end

local function create(current, syntax)
  current.keyword = base.keyword(current.line, current.col)
  current.clients = {}
  local clients = vim.lsp.get_clients {
    bufnr = current.buf,
    method = "textDocument/completion",
  }
  current.single_client = #clients == 1
  for _, client in ipairs(clients) do
    current.clients[client.id] = client
  end
  current.context = syntax or { kind = "unknown", spans = {} }
  current.keys = setmetatable({}, { __mode = "k" })
  current.key_count = 0
  current.word_sets = {}
  return current
end

function M.prepare()
  local current = state()
  if same(snapshot, current) and snapshot.prepared then
    return snapshot
  end
  sorting = nil
  snapshot = create(current, context.capture(current))
  snapshot.prepared = true
  return snapshot
end

local function current_snapshot()
  if sorting then
    return sorting
  end
  local current = state()
  if not same(snapshot, current) then
    -- Never parse or walk syntax during table.sort. A stale snapshot is neutral.
    snapshot = create(current)
  end
  sorting = snapshot
  vim.schedule(function()
    sorting = nil
  end)
  return sorting
end

-- Stable serialization is a final identity key, never a ranking signal.
local function canonical(value)
  if type(value) ~= "table" then
    return type(value) .. ":" .. string.format("%q", tostring(value))
  end
  local parts = {}
  for _, key in ipairs(vim.tbl_keys(value)) do
    parts[#parts + 1] = {
      key = type(key) .. ":" .. string.format("%q", tostring(key)),
      value = value[key],
    }
  end
  table.sort(parts, function(a, b)
    return a.key < b.key
  end)
  local out = {}
  for _, part in ipairs(parts) do
    out[#out + 1] = part.key .. "=" .. canonical(part.value)
  end
  return "{" .. table.concat(out, ";") .. "}"
end

local function lower(text)
  return text:find "[\128-\255]" and vim.fn.tolower(text) or text:lower()
end

local function text_key(text, query)
  if not query then
    return 5, 0
  elseif query == "" then
    return 0, 0
  end
  local lower_text, lower_query = lower(text), lower(query)
  local class = text == query and 0
    or lower_text == lower_query and 1
    or vim.startswith(text, query) and 2
    or vim.startswith(lower_text, lower_query) and 3
    or 4
  local scores = vim.fn.matchfuzzypos({ text }, query)[3]
  return class, -(scores[1] or 0)
end

local function item_key(candidate, current)
  local cached = current.keys[candidate]
  if cached then
    return cached
  end
  local data = type(candidate.user_data) == "table" and candidate.user_data
    or {}
  local lsp = vim.tbl_get(data, "nvim", "lsp") or {}
  local item = lsp.completion_item or {}
  local label = item.label or candidate.abbr or candidate.word or ""
  local client = current.clients[lsp.client_id]
  local query, start = base.get(current, item, client)
  local class, score = text_key(item.filterText or label, query)
  local affinity = 0
  if query then
    local group = tostring(start) .. ":" .. query
    local line_words = current.word_sets[group]
    if not line_words then
      line_words = {}
      local query_words = context.words(query, current.context.keywords)
      for _, span in ipairs(current.context.spans) do
        if span.finish <= start or span.start >= current.col then
          for word in pairs(context.words(span.text, current.context.keywords)) do
            if not query_words[word] then
              line_words[word] = true
            end
          end
        end
      end
      current.word_sets[group] = line_words
    end
    local name = item.filterText or label:match "^[^%s(]+" or label
    for word in pairs(context.words(name, current.context.keywords)) do
      if line_words[word] then
        affinity = affinity + 1
      end
    end
  end
  local deprecated = item.deprecated or vim.tbl_contains(item.tags or {}, 1)
  local key = {
    class,
    -affinity,
    score,
    deprecated and 1 or 0,
    current.single_client and (item.sortText or label) or "",
    context.fit(current.context, item.kind),
    item.kind == vim.lsp.protocol.CompletionItemKind.Snippet and 1 or 0,
    lower(label),
    label,
    client and (client.name .. ":" .. (client.root_dir or "")) or "",
    tostring(lsp.client_id or ""),
  }
  -- Compute canonical edit identity only when the earlier tuple actually ties.
  current.keys[candidate] = { tuple = key, item = item, word = candidate.word }
  current.key_count = current.key_count + 1
  return current.keys[candidate]
end

local function less(a, b, current)
  local ka, kb = item_key(a, current), item_key(b, current)
  for i, value in ipairs(ka.tuple) do
    if value ~= kb.tuple[i] then
      return value < kb.tuple[i]
    end
  end
  for _, key in ipairs { ka, kb } do
    if not key.identity then
      key.identity = canonical {
        word = key.word,
        kind = key.item.kind,
        detail = key.item.detail,
        labels = key.item.labelDetails,
        edit = key.item.textEdit,
        insert = key.item.insertText,
        format = key.item.insertTextFormat,
        additional = key.item.additionalTextEdits,
        command = key.item.command,
        data = key.item.data,
      }
    end
  end
  return ka.identity < kb.identity
end

function M.compare(a, b)
  return less(a, b, current_snapshot())
end

-- Returns an immutable snapshot comparator for fixtures and profiling.
function M.comparator(current)
  current.context = current.context or { kind = "unknown", spans = {} }
  current.clients = current.clients or {}
  current.keys = setmetatable({}, { __mode = "k" })
  current.word_sets = {}
  current.key_count = 0
  return function(a, b)
    return less(a, b, current)
  end, current
end

function M.shorten(text, width)
  text = (text or ""):gsub("[%z\1-\31\127]", " ")
  if vim.fn.strdisplaywidth(text) <= width then
    return text
  end
  local result = ""
  -- skipcc=true keeps combining marks attached to their preceding character.
  for i = 0, vim.fn.strchars(text, true) - 1 do
    local char = vim.fn.strcharpart(text, i, 1, true)
    if vim.fn.strdisplaywidth(result .. char .. "…") > width then
      break
    end
    result = result .. char
  end
  return result .. "…"
end

function M.convert(item)
  return {
    abbr = M.shorten(item.label or "", 45),
    menu = M.shorten(
      vim.tbl_get(item, "labelDetails", "description") or item.detail or "",
      24
    ),
  }
end

return M
