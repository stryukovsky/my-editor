local M = {}
local languages = require "native_completion.languages"
local queries = {}

-- Whole identifier components, not substrings: HTTPUser_ID2 -> http,user,id.
function M.words(text, keywords)
  -- Keep the original one-argument helper compatible with its former stop list.
  local defaults = not keywords and languages.get "lua"
  keywords = keywords or defaults and defaults.keyword_set or {}
  text = text:gsub("(%u)(%u%l)", "%1 %2"):gsub("(%l)(%u)", "%1 %2")
  local words = {}
  for word in text:gmatch "[%a\128-\255]+" do
    word = word:find "[\128-\255]" and vim.fn.tolower(word) or word:lower()
    if not keywords[word] then
      words[word] = true
    end
  end
  return words
end

local function contains(node, row, col)
  local sr, sc, er, ec = node:range()
  return (row > sr or row == sr and col >= sc)
    and (row < er or row == er and col < ec)
end

local function classification(node, mapping)
  local ancestors = {}
  for _ = 1, 20 do
    if not node then
      break
    end
    local kind = node:type()
    if node:missing() or kind == "ERROR" or mapping.comments[kind] then
      return "unknown"
    end
    if mapping.excluded[kind] then
      local parent = node:parent()
      for _ = 1, 5 do
        if not parent then
          break
        end
        local context = mapping.string_parents[parent:type()]
        if context then
          return parent:has_error() and "unknown" or context
        end
        parent = parent:parent()
      end
      return "unknown"
    end
    ancestors[#ancestors + 1] = node
    node = node:parent()
  end
  for index, ancestor in ipairs(ancestors) do
    local rule = mapping.contexts[ancestor:type()]
    if rule then
      local matches = not rule.field
      if rule.field and ancestors[index - 1] then
        for _, child in ipairs(ancestor:field(rule.field)) do
          if child:id() == ancestors[index - 1]:id() then
            matches = true
          end
        end
      end
      for _, field in ipairs(rule.requires) do
        if #ancestor:field(field) == 0 then
          matches = false
        end
      end
      for _, excluded in ipairs(rule.unless_ancestor) do
        for parent_index = index + 1, #ancestors do
          if ancestors[parent_index]:type() == excluded then
            matches = false
          end
        end
      end
      if matches then
        return ancestor:has_error() and "unknown" or rule.context
      end
    end
  end
  return "unknown"
end

-- Called by editor events, never by the comparator. Does not install parsers.
function M.capture(state)
  local empty = { kind = "unknown", spans = {} }
  local lang = vim.treesitter.language.get_lang(vim.bo[state.buf].filetype)
  if
    not languages.get(lang)
    or vim.b[state.buf].skip_heavy_operations
    or vim.b[state.buf].large_file
  then
    return empty
  end
  local ok, parser = pcall(vim.treesitter.get_parser, state.buf)
  if not ok or not parser then
    return empty
  end
  local parsed = pcall(parser.parse, parser, { state.row, state.row + 1 })
  if not parsed then
    return empty
  end
  local result = { kind = "unknown", spans = {} }
  local probe = math.max(0, state.col - 1)
  -- Move back to a UTF-8 codepoint boundary before asking for a syntax node.
  while
    probe > 0
    and (state.line:byte(probe + 1) or 0) >= 128
    and (state.line:byte(probe + 1) or 0) < 192
  do
    probe = probe - 1
  end
  local range = { state.row, probe, state.row, probe + 1 }
  local tree = parser
  for _ = 1, 16 do
    local child_at_cursor
    for _, child in pairs(tree:children()) do
      if child:contains(range) then
        if child_at_cursor then
          return empty
        end
        child_at_cursor = child
      end
    end
    if not child_at_cursor then
      break
    end
    tree = child_at_cursor
  end
  local mapping = tree and languages.get(tree:lang())
  if not mapping or not tree:is_valid(true, { state.row, state.row + 1 }) then
    return empty
  end
  local trees = tree:trees()
  local syntax
  for _, candidate in ipairs(trees) do
    if contains(candidate:root(), state.row, probe) then
      if syntax then -- Overlapping injected regions are ambiguous.
        return empty
      end
      syntax = candidate:root()
    end
  end
  if not syntax then
    return empty
  end
  local node =
    syntax:named_descendant_for_range(state.row, probe, state.row, probe)
  result.kind = classification(node, mapping)
  result.keywords = mapping.keyword_set
  -- Query only this row, instead of scanning sibling declarations in the file.
  local language = tree:lang()
  if queries[language] == nil then
    local nodes = {}
    for _, name in ipairs(mapping.identifier_nodes) do
      nodes[#nodes + 1] = "(" .. name .. ")"
    end
    local ok, query = pcall(
      vim.treesitter.query.parse,
      language,
      "[" .. table.concat(nodes, " ") .. "] @id"
    )
    queries[language] = ok and query or false
    if not ok then
      vim.schedule(function()
        vim.notify_once(
          "Native completion identifier nodes for "
            .. language
            .. ": "
            .. tostring(query),
          vim.log.levels.WARN
        )
      end)
    end
  end
  if not queries[language] then
    return empty
  end
  local count = 0
  for _, identifier in
    queries[language]:iter_captures(syntax, state.buf, state.row, state.row + 1)
  do
    count = count + 1
    if count > 256 then
      result.spans = {}
      break
    end
    local sr, sc, er, ec = identifier:range()
    local ancestor = identifier
    local allowed = sr == state.row and er == state.row
    for _ = 1, 20 do
      if not ancestor then
        break
      end
      if
        mapping.excluded[ancestor:type()]
        or ancestor:type() == "ERROR"
        or ancestor:missing()
      then
        allowed = false
        break
      end
      ancestor = ancestor:parent()
    end
    if allowed then
      result.spans[#result.spans + 1] =
        { start = sc, finish = ec, text = state.line:sub(sc + 1, ec) }
    end
  end
  return result
end

function M.affinity(context, name, base, start, finish)
  local query_words = M.words(base or "", context.keywords)
  local line_words = {}
  for _, span in ipairs(context.spans) do
    if span.finish <= start or span.start >= finish then
      for word in pairs(M.words(span.text, context.keywords)) do
        if not query_words[word] then
          line_words[word] = true
        end
      end
    end
  end
  local count = 0
  for word in pairs(M.words(name, context.keywords)) do
    if line_words[word] then
      count = count + 1
    end
  end
  return count
end

local kinds = vim.lsp.protocol.CompletionItemKind
local hints = {
  type = {
    kinds.Class,
    kinds.Interface,
    kinds.Struct,
    kinds.Enum,
    kinds.TypeParameter,
  },
  method = { kinds.Method, kinds.Function },
  member = {
    kinds.Method,
    kinds.Function,
    kinds.Field,
    kinds.Property,
    kinds.Constant,
    kinds.EnumMember,
  },
  import = { kinds.Module, kinds.File, kinds.Folder },
}
function M.fit(context, kind)
  return vim.tbl_contains(hints[context.kind] or {}, kind) and 0 or 1
end

return M
