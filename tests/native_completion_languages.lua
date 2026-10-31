-- nvim --headless -u NONE -i NONE -l tests/native_completion_languages.lua [root]
local root = arg[1] or vim.fn.getcwd()
local config = vim.env.NVIM_CONFIG_ROOT or root
vim.opt.rtp:prepend(root)
vim.opt.rtp:append(config)
vim.opt.rtp:append(config .. "/data/tree-sitter")
local languages = require "native_completion.languages"
local context = require "native_completion.context"
local checks, fixtures = 0, 0
local function eq(actual, expected, label)
  checks = checks + 1
  assert(
    vim.deep_equal(actual, expected),
    label .. ": " .. vim.inspect(actual) .. " ~= " .. vim.inspect(expected)
  )
end

for _, language in ipairs(languages.list()) do
  local mapping =
    assert(languages.get(language), "invalid mapping: " .. language)
  -- Data must name actual named nodes, including nodes not used in the query.
  assert(
    vim.treesitter.language.add(language),
    "missing test parser: " .. language
  )
  local inspected = vim.treesitter.language.inspect(language)
  local symbols = inspected.symbols
  local function named(nodes)
    for _, name in ipairs(nodes) do
      local node = type(name) == "table" and name.node or name
      eq(symbols[node], true, language .. " named node " .. node)
      if type(name) == "table" then
        eq(
          vim.tbl_contains(inspected.fields, name.field),
          true,
          language .. " field " .. name.field
        )
        for _, ancestor in ipairs(name.unless_ancestor or {}) do
          eq(
            symbols[ancestor],
            true,
            language .. " excluded ancestor " .. ancestor
          )
        end
        for _, field in ipairs(name.requires or {}) do
          eq(
            vim.tbl_contains(inspected.fields, field),
            true,
            language .. " required field " .. field
          )
        end
      end
    end
  end
  named(mapping.identifier_nodes)
  named(mapping.comment_nodes)
  named(mapping.string_nodes)
  for _, nodes in pairs(mapping.expressions) do
    named(nodes)
  end
  for _, nodes in pairs(mapping.string_contexts) do
    named(nodes)
  end
  eq(
    context.words(table.concat(mapping.keywords, " "), mapping.keyword_set),
    {},
    language .. " keyword exclusions"
  )
  for _, fixture in ipairs(mapping.fixtures) do
    fixtures = fixtures + 1
    local label = language .. "/" .. fixture.name
    local marker = assert(
      fixture.source:find("<cursor>", 1, true),
      label .. " missing cursor"
    )
    assert(
      not fixture.source:find("<cursor>", marker + 1, true),
      label .. " has multiple cursors"
    )
    local before = fixture.source:sub(1, marker - 1)
    local source = before .. fixture.source:sub(marker + #"<cursor>")
    local row = select(2, before:gsub("\n", ""))
    local col = #(before:match "[^\n]*$" or "")
    local lines = vim.split(source, "\n", { plain = true })
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.bo[buf].filetype = language
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local result =
      context.capture { buf = buf, row = row, col = col, line = lines[row + 1] }
    eq(result.kind, fixture.expect.context, label .. " context")
    if fixture.expect.identifiers then
      local names = {}
      for _, span in ipairs(result.spans) do
        names[#names + 1] = span.text
      end
      eq(names, fixture.expect.identifiers, label .. " identifiers")
    end
    for name, expected in pairs(fixture.expect.affinity or {}) do
      local base =
        require("native_completion.base").keyword(lines[row + 1], col)
      eq(
        context.affinity(result, name, base, col - #base, col),
        expected,
        label .. " affinity " .. name
      )
    end
    if fixture.expect.ranking then
      local candidates = {}
      for _, name in ipairs(fixture.expect.ranking) do
        candidates[#candidates + 1] = {
          word = name,
          user_data = {
            nvim = { lsp = { completion_item = { label = name } } },
          },
        }
      end
      -- Reverse the input so a fixture cannot pass just by retaining input order.
      local reversed = {}
      for i = #candidates, 1, -1 do
        reversed[#reversed + 1] = candidates[i]
      end
      local compare = require("native_completion").comparator {
        line = lines[row + 1],
        row = row,
        col = col,
        context = result,
      }
      table.sort(reversed, compare)
      local names = {}
      for _, candidate in ipairs(reversed) do
        names[#names + 1] = candidate.word
      end
      eq(names, fixture.expect.ranking, label .. " ranking")
    end
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  print(language .. ": " .. #mapping.fixtures .. " parser fixtures passed")
end
-- Broken data must disable only its own adapter and report one diagnostic.
local temporary = vim.fn.tempname()
local directory = temporary .. "/lua/native_completion/languages"
vim.fn.mkdir(directory, "p")
vim.opt.rtp:prepend(temporary)
local warnings = 0
local notify = vim.notify_once
vim.notify_once = function()
  warnings = warnings + 1
end
for name, data in pairs {
  broken_json = "{",
  broken_groups = vim.json.encode {
    version = 1,
    language = "broken_groups",
    extends = "lua",
    expressions = { bogus = { "identifier" } },
    fixtures = { {} },
  },
  broken_expression = vim.json.encode {
    version = 1,
    language = "broken_expression",
    extends = "lua",
    expressions = { member = { { node = "identifier", field = 1 } } },
    fixtures = { {} },
  },
  cycle_a = vim.json.encode {
    version = 1,
    language = "cycle_a",
    extends = "cycle_b",
    fixtures = { {} },
  },
  cycle_b = vim.json.encode {
    version = 1,
    language = "cycle_b",
    extends = "cycle_a",
    fixtures = { {} },
  },
} do
  vim.fn.writefile({ data }, directory .. "/" .. name .. ".json")
end
for _, name in ipairs {
  "broken_json",
  "broken_groups",
  "broken_expression",
  "cycle_a",
} do
  eq(languages.get(name), nil, name .. " neutral")
  eq(languages.get(name), nil, name .. " cached failure")
end
vim.wait(10, function()
  return warnings == 4
end)
eq(warnings, 4, "one diagnostic per invalid adapter")
vim.notify_once = notify
vim.opt.rtp:remove(temporary)
vim.fn.delete(temporary, "rf")
print(
  ("PASS %d mapping/grammar checks across %d fixtures"):format(checks, fixtures)
)
vim.cmd "qa!"
