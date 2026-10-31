local M = {}
local cache = {}
local contexts = { type = true, method = true, member = true, import = true }
local fields = {
  "identifier_nodes",
  "comment_nodes",
  "string_nodes",
  "keywords",
  "expressions",
  "string_contexts",
}

local function list(value)
  if type(value) ~= "table" or not vim.islist(value) then
    return false
  end
  for _, item in ipairs(value) do
    if type(item) ~= "string" or item == "" then
      return false
    end
  end
  return true
end

local function expression_list(value)
  if type(value) ~= "table" or not vim.islist(value) then
    return false
  end
  for _, node in ipairs(value) do
    if type(node) ~= "string" then
      if
        type(node) ~= "table"
        or type(node.node) ~= "string"
        or type(node.field) ~= "string"
        or node.requires ~= nil and not list(node.requires)
        or node.unless_ancestor ~= nil and not list(node.unless_ancestor)
      then
        return false
      end
    end
  end
  return true
end

local function context_groups(value, expressions)
  if type(value) ~= "table" then
    return false
  end
  for kind, nodes in pairs(value) do
    if
      not contexts[kind]
      or not (
        expressions and expression_list(nodes)
        or not expressions and list(nodes)
      )
    then
      return false
    end
  end
  return true
end

local function validate(raw, language)
  assert(
    type(raw) == "table" and raw.version == 1 and raw.language == language,
    "expected version 1 and matching language"
  )
  assert(
    raw.extends == nil
      or type(raw.extends) == "string"
        and raw.extends:match "^[a-z][a-z0-9_]*$",
    "invalid parent mapping"
  )
  for _, key in ipairs(fields) do
    if raw[key] ~= nil then
      local grouped = key == "expressions" or key == "string_contexts"
      local valid
      if grouped then
        valid = context_groups(raw[key], key == "expressions")
      else
        valid = list(raw[key])
      end
      assert(valid, "invalid " .. key)
    elseif not raw.extends then
      error("missing " .. key)
    end
  end
  assert(
    type(raw.fixtures) == "table"
      and vim.islist(raw.fixtures)
      and #raw.fixtures > 0,
    "missing parser fixtures"
  )
end

local function resolve(language, visiting)
  if type(language) ~= "string" or not language:match "^[a-z][a-z0-9_]*$" then
    return nil
  end
  if visiting[language] then
    error("cyclic mapping inheritance: " .. language)
  end
  if cache[language] ~= nil then
    return cache[language] or nil
  end
  local paths = vim.api.nvim_get_runtime_file(
    "lua/native_completion/languages/" .. language .. ".json",
    false
  )
  if not paths[1] then
    cache[language] = false
    return nil
  end
  local raw = vim.json.decode(table.concat(vim.fn.readfile(paths[1]), "\n"))
  validate(raw, language)
  visiting[language] = true
  local parent = raw.extends and resolve(raw.extends, visiting)
  assert(
    not raw.extends or parent,
    "missing parent mapping: " .. tostring(raw.extends)
  )
  visiting[language] = nil
  local mapping = { language = language, path = paths[1], fixtures = {} }
  for _, key in ipairs(fields) do
    mapping[key] = raw[key] or parent and parent[key] or {}
  end
  assert(#mapping.identifier_nodes > 0, "mapping needs identifier nodes")
  for _, fixture in ipairs(parent and parent.fixtures or {}) do
    mapping.fixtures[#mapping.fixtures + 1] = fixture
  end
  for _, fixture in ipairs(raw.fixtures) do
    mapping.fixtures[#mapping.fixtures + 1] = fixture
  end
  mapping.excluded = {}
  mapping.comments = {}
  mapping.keyword_set = {}
  mapping.contexts = {}
  mapping.string_parents = {}
  for _, node in ipairs(mapping.comment_nodes) do
    mapping.comments[node] = true
    mapping.excluded[node] = true
  end
  for _, node in ipairs(mapping.string_nodes) do
    mapping.excluded[node] = true
  end
  for _, word in ipairs(mapping.keywords) do
    mapping.keyword_set[word] = true
  end
  for kind, nodes in pairs(mapping.expressions) do
    for _, entry in ipairs(nodes) do
      local rule = type(entry) == "string" and { node = entry } or entry
      assert(
        not mapping.contexts[rule.node],
        "node has competing contexts: " .. rule.node
      )
      mapping.contexts[rule.node] = {
        context = kind,
        field = rule.field,
        requires = rule.requires or {},
        unless_ancestor = rule.unless_ancestor or {},
      }
    end
  end
  for kind, nodes in pairs(mapping.string_contexts) do
    for _, node in ipairs(nodes) do
      assert(
        not mapping.string_parents[node],
        "string parent has competing contexts: " .. node
      )
      mapping.string_parents[node] = kind
    end
  end
  cache[language] = mapping
  return mapping
end

function M.get(language)
  local ok, mapping = pcall(resolve, language, {})
  if ok then
    return mapping
  end
  cache[language] = false
  vim.schedule(function()
    vim.notify_once(
      "Native completion mapping "
        .. tostring(language)
        .. ": "
        .. tostring(mapping),
      vim.log.levels.WARN
    )
  end)
  return nil
end

function M.list()
  local names = {}
  for _, path in
    ipairs(
      vim.api.nvim_get_runtime_file(
        "lua/native_completion/languages/*.json",
        true
      )
    )
  do
    names[vim.fs.basename(path):gsub("%.json$", "")] = true
  end
  local result = vim.tbl_keys(names)
  table.sort(result)
  return result
end

return M
