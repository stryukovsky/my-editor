-- nvim --headless -u NONE -i NONE -l tests/native_completion.lua [project-root]
local root = arg[1] or vim.fn.getcwd()
vim.opt.rtp:prepend(root)
local config = vim.env.NVIM_CONFIG_ROOT or root
vim.opt.rtp:append(config)
vim.opt.rtp:append(config .. "/data/tree-sitter")
local base = require "native_completion.base"
local checks = 0
local function eq(actual, expected, label)
  checks = checks + 1
  assert(
    vim.deep_equal(actual, expected),
    (label or "check")
      .. ": "
      .. vim.inspect(actual)
      .. " ~= "
      .. vim.inspect(expected)
  )
end
local function state(line)
  return { line = line, row = 0, col = #line }
end
for _, case in ipairs {
  { "print", {}, "print" },
  { "object.pr", {}, "pr" },
  { "", {}, "" },
  { "object.", {}, "" },
  { "path/", {}, "" },
  { "print", { label = "print(value)", filterText = "print" }, "print" },
  {
    "object.pr",
    {
      label = "print",
      textEdit = { range = { start = { line = 0, character = 7 } } },
    },
    "pr",
  },
  {
    "object.pr",
    {
      label = "print",
      textEdit = { range = { start = { line = 0, character = 0 } } },
    },
    "pr",
  },
  {
    "😀é.pr",
    {
      label = "print",
      textEdit = { range = { start = { line = 0, character = 4 } } },
    },
    "pr",
  },
  {
    "abc",
    { textEdit = { range = { start = { line = 1, character = 0 } } } },
    false,
  },
  {
    "abc",
    { textEdit = { range = { start = { line = 0, character = 99 } } } },
    false,
  },
} do
  eq(base.get(state(case[1]), case[2]) or false, case[3], "completion base")
end
local rank = require "native_completion"
local context = require "native_completion.context"
local K = vim.lsp.protocol.CompletionItemKind
local function candidate(label, kind, extra, client)
  local item =
    vim.tbl_extend("force", { label = label, kind = kind }, extra or {})
  return {
    word = label,
    user_data = {
      nvim = { lsp = { completion_item = item, client_id = client or 1 } },
    },
  }
end
local function before(line, a, b, options)
  local cmp =
    rank.comparator(vim.tbl_extend("force", state(line), options or {}))
  eq(cmp(a, b), true, "ranking precedence")
  eq(cmp(b, a), false, "ranking reverse")
end
before(
  "print",
  candidate("print", K.Function),
  candidate("printOptions", K.Variable)
)
before("pri", candidate("pri", K.Variable), candidate("print", K.Function))
before(
  "abc",
  candidate("a_b_c", K.Function),
  candidate("a----b----c", K.Variable)
)
before(
  "print",
  candidate("print", K.Function, { deprecated = true }),
  candidate("printOptions", K.Variable)
)
before("get", candidate "getValue", candidate "GetValue")
before("feat", candidate("feat", K.Snippet), candidate("feature", K.Variable))
before("", candidate "x", candidate("x", nil, { deprecated = true }))
before("", candidate "x", candidate("x", nil, { tags = { 1 } }))
before("", candidate("x", K.Variable), candidate("x", K.Snippet))
before(
  "",
  candidate("variable", K.Variable, { sortText = "a" }),
  candidate("Type", K.Class, { sortText = "b" }),
  {
    single_client = true,
    context = { kind = "type", spans = {} },
  }
)
before(
  "",
  candidate("aaa", nil, { sortText = "z" }, 2),
  candidate("zzz", nil, { sortText = "a" }, 1),
  { single_client = false }
)
for _, text in ipairs {
  "",
  "a\nb\tc\rd\127",
  string.rep("界", 60),
  string.rep("é", 60),
  string.rep("x", 100),
} do
  local converted = rank.convert { label = text, detail = text }
  eq(vim.fn.strdisplaywidth(converted.abbr) <= 45, true, "name width")
  eq(vim.fn.strdisplaywidth(converted.menu) <= 24, true, "menu width")
  eq(converted.abbr:find "[%z\1-\31\127]" == nil, true, "single line")
end
local sample = {
  candidate("a", K.Variable, { sortText = "z" }),
  candidate("b", K.Class, { sortText = "a" }, 2),
  candidate("a", K.Method),
  candidate("a", K.Snippet),
  candidate("a", nil, { textEdit = { newText = "other" } }),
  candidate("a", nil, { additionalTextEdits = { { newText = "import A" } } }),
  { word = "a" },
}
sample[#sample + 1] = candidate("a", nil, { data = { "module" } })
sample[#sample + 1] = candidate("a", nil, { data = { ["1"] = "module" } })
local cmp = rank.comparator(state "")
for _, a in ipairs(sample) do
  eq(cmp(a, a), false, "irreflexive")
  for _, b in ipairs(sample) do
    for _, c in ipairs(sample) do
      if cmp(a, b) and cmp(b, c) then
        eq(cmp(a, c), true, "transitive")
      end
    end
  end
end
local expected
for seed = 1, 30 do
  math.randomseed(seed)
  local items = vim.deepcopy(sample)
  for i = #items, 2, -1 do
    local j = math.random(i)
    items[i], items[j] = items[j], items[i]
  end
  table.sort(items, rank.comparator(state ""))
  expected = expected or vim.inspect(items)
  eq(vim.inspect(items), expected, "shuffle order")
end
local function syntax(ft, line, col)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.bo[buf].filetype = ft
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { line })
  return context.capture { buf = buf, row = 0, col = col or #line, line = line },
    buf
end
-- Language-specific parser cases live beside their JSON adapters.
eq(
  syntax("unknown_test_language", "User create", 11).kind,
  "unknown",
  "unsupported language neutral"
)
local ctx = syntax("typescript", "const user: User = create")
before(
  "const user: User = create",
  candidate "createUser",
  candidate "createCat",
  { context = ctx }
)
before(
  "const user: User = createCat",
  candidate "createCat",
  candidate "createUser",
  { context = ctx }
)
eq(
  context.words "HTTPUser_ID2",
  { http = true, user = true, id = true },
  "identifier components"
)
for _, line in ipairs { 'const x = "User"; create', "// User create", "create" } do
  local c = syntax("typescript", line)
  eq(
    context.affinity(c, "createUser", "create", #line - 6, #line),
    0,
    "prose/query exclusion"
  )
end
local repeated = syntax("typescript", "User(User, User); create")
eq(
  context.affinity(repeated, "createUser", "create", 17, 23),
  1,
  "distinct words only"
)
eq(
  context.affinity(repeated, "abuser", "create", 17, 23),
  0,
  "no substring match"
)
before(
  "",
  candidate("x", K.Class, { sortText = "same" }),
  candidate("x", K.Variable, { sortText = "same" }),
  { single_client = true, context = { kind = "type", spans = {} } }
)
before(
  "",
  candidate("x", K.Method),
  candidate("x", K.Field),
  { context = { kind = "method", spans = {} } }
)
eq(
  context.fit({ kind = "member" }, K.Method),
  context.fit({ kind = "member" }, K.Field),
  "dot kinds equal"
)
local heavy, heavy_buf = syntax("typescript", "const user: User = create")
for _, flag in ipairs { "skip_heavy_operations", "large_file" } do
  vim.b[heavy_buf][flag] = true
  local disabled = context.capture {
    buf = heavy_buf,
    row = 0,
    col = 25,
    line = "const user: User = create",
  }
  eq(disabled.spans, {}, "large-file context disabled")
  vim.b[heavy_buf][flag] = nil
end
local unrelated = syntax("typescript", "let x: User; ???", 11)
eq(unrelated.kind, "type", "unrelated syntax error does not suppress hint")
local malformed = syntax("typescript", "let x: ;", 7)
eq(malformed.kind, "unknown", "malformed local syntax neutral")
local missing_parser = vim.treesitter.get_parser
vim.treesitter.get_parser = function()
  return nil
end
local unavailable = syntax("lua", "User create")
eq(unavailable.spans, {}, "missing parser neutral")
vim.treesitter.get_parser = missing_parser
local function injected(language)
  vim.treesitter.query.set(
    "typescript",
    "injections",
    '((string_fragment) @injection.content (#set! injection.language "'
      .. language
      .. '"))'
  )
  return syntax("typescript", "const code = `obj:print()`", 22)
end
local injection = injected "lua"
eq(injection.kind, "method", "supported active injected language")
-- Pick an installed grammar without a mapping; Python is now supported.
local unsupported_language
for _, path in ipairs(vim.api.nvim_get_runtime_file("parser/*", true)) do
  local language = vim.fs.basename(path):gsub("%.[^.]+$", "")
  if not require("native_completion.languages").get(language) then
    local ok, added = pcall(vim.treesitter.language.add, language)
    if ok and added then
      unsupported_language = language
      break
    end
  end
end
assert(
  unsupported_language,
  "unsupported-injection fixture needs an unmapped installed parser"
)
local unsupported = injected(unsupported_language)
eq(unsupported.kind, "unknown", "unsupported injected language neutral")
vim.treesitter.query.set(
  "typescript",
  "injections",
  [=[
((string_fragment) @injection.content (#set! injection.language "lua"))
((string_fragment) @injection.content (#set! injection.language "python"))
]=]
)
local ambiguous = syntax("typescript", "const code = `obj:print()`", 22)
eq(ambiguous.kind, "unknown", "competing injected languages neutral")
vim.treesitter.query.set("typescript", "injections", nil)
local capture = context.capture
local captures = 0
context.capture = function(s)
  captures = captures + 1
  return capture(s)
end
local c, buf = syntax("typescript", "const user: User = create")
vim.api.nvim_win_set_cursor(0, { 1, #"const user: User = create" - 1 })
-- 'onemore' permits a normal-mode fixture cursor at the insertion position.
vim.o.virtualedit = "onemore"
vim.api.nvim_win_set_cursor(0, { 1, #"const user: User = create" })
rank.invalidate()
local snap = rank.prepare()
local initial = captures
local candidates = { candidate "createCat", candidate "createUser" }
table.sort(candidates, rank.compare)
eq(candidates[1].word, "createUser", "editor snapshot affinity")
eq(captures, initial, "no syntax capture in compare")
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "const cat: Cat = create" })
vim.api.nvim_win_set_cursor(0, { 1, #"const cat: Cat = create" })
rank.invalidate()
rank.prepare()
table.sort(candidates, rank.compare)
eq(candidates[1].word, "createCat", "line-only context invalidation")
context.capture = capture
-- Profile prepared keys without a machine-dependent pass/fail threshold.
local bulk = {}
for i = 1, 1000 do
  bulk[i] = candidate((i % 2 == 0 and "createUser" or "createCat") .. i)
end
local perf =
  vim.tbl_extend("force", state "const user: User = create", { context = ctx })
local sorter, cache = rank.comparator(perf)
local started = vim.uv.hrtime()
table.sort(bulk, sorter)
local elapsed = (vim.uv.hrtime() - started) / 1e6
eq(cache.key_count, 1000, "one key per candidate")
print(
  ("PASS %d boundary, ranking, syntax, display and comparator checks; 1000 items %.2f ms"):format(
    checks,
    elapsed
  )
)
vim.cmd "qa!"
