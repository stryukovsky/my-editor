-- Ripgrep / ast-grep "LSP-ish" navigation for heavy projects.
-- Scoped to the current file extension (rg) or language (ast-grep).

local is_normal_buffer = require "utils.is_normal_buffer"
local M = {}
local notify = require "configs.notify"

local DEFINITION_KEYWORDS = "var|val|const|let|class|function|func|def"

---@param word? string
---@return string|nil
local function resolve_word(word)
  if word and vim.trim(word) ~= "" then
    return vim.trim(word)
  end
  local cword = vim.fn.expand "<cword>"
  if vim.trim(cword) == "" then
    return nil
  end
  return cword
end

---@return string|nil extension without dot
local function current_extension()
  if not is_normal_buffer() then
    return nil
  end
  local ext = vim.fn.expand "%:e"
  if ext == "" then
    return nil
  end
  return ext
end

---@param word string
---@return string
local function escape_rg(word)
  return vim.fn.escape(word, [[\^$.*+?()[]{}|]])
end

---True when the word under the cursor is followed by `(` (call site).
---@param word string
---@return boolean
local function is_call_site(word)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] -- 0-based
  local right = line:sub(col + 1):match "^[%w_]*" or ""
  local after = line:sub(col + 1 + #right)
  return after:match "^%s*%(" ~= nil
end

---@param pattern string
---@param title string
---@param ext string
local function live_grep(pattern, title, ext)
  require("telescope.builtin").live_grep {
    default_text = pattern,
    glob_pattern = "*." .. ext,
    initial_mode = "normal",
    prompt_title = title,
    results_title = "*." .. ext,
  }
end

---Find definition via keyword + name (rg). Optional `word`; defaults to `<cword>`.
---@param word? string
function M.find_definition(word)
  local symbol = resolve_word(word)
  if not symbol then
    notify.send("ripgrelsp", "No word under cursor", vim.log.levels.WARN)
    return
  end

  local ext = current_extension()
  if not ext then
    notify.send("ripgrelsp", "Current buffer has no file extension", vim.log.levels.WARN)
    return
  end

  local pattern = ("(%s)\\s+%s"):format(DEFINITION_KEYWORDS, escape_rg(symbol))
  live_grep(pattern, "rg definition: " .. symbol, ext)
end

---Find usages. Call sites search `\.?word\(`; otherwise plain word search.
---@param word? string
function M.find_usages(word)
  local symbol = resolve_word(word)
  if not symbol then
    notify.send("ripgrelsp", "No word under cursor", vim.log.levels.WARN)
    return
  end

  local ext = current_extension()
  if not ext then
    notify.send("ripgrelsp", "Current buffer has no file extension", vim.log.levels.WARN)
    return
  end

  local escaped = escape_rg(symbol)
  local pattern
  local title
  if is_call_site(symbol) then
    pattern = "\\.?" .. escaped .. "\\s*\\("
    title = "rg call usages: " .. symbol
  else
    pattern = "\\b" .. escaped .. "\\b"
    title = "rg usages: " .. symbol
  end

  live_grep(pattern, title, ext)
end

--------------------------------------------------------------------------------
-- ast-grep backend
--------------------------------------------------------------------------------

local FT_TO_LANG = {
  scala = "scala",
  sbt = "scala",
  python = "python",
  go = "go",
  rust = "rust",
  lua = "lua",
  javascript = "javascript",
  javascriptreact = "javascript",
  typescript = "typescript",
  typescriptreact = "tsx",
  java = "java",
  kotlin = "kotlin",
  c = "c",
  cpp = "cpp",
  objc = "objc",
  ruby = "ruby",
  php = "php",
  csharp = "csharp",
  html = "html",
  css = "css",
  json = "json",
  yaml = "yaml",
  bash = "bash",
  sh = "bash",
  zsh = "bash",
  zig = "zig",
  elixir = "elixir",
  haskell = "haskell",
  solidity = "solidity",
  swift = "swift",
}

---@return string|nil
local function resolve_ast_grep()
  if vim.fn.executable "ast-grep" == 1 then
    return "ast-grep"
  end
  local mason = vim.fn.stdpath "data" .. "/mason/bin/ast-grep"
  if vim.fn.executable(mason) == 1 then
    return mason
  end
  -- Prefer not to use bare `sg`: on many systems it is shadow-utils, not ast-grep.
  return nil
end

---@return string|nil
local function current_sg_lang()
  if not is_normal_buffer() then
    return nil
  end
  return FT_TO_LANG[vim.bo.filetype]
end

---@param name string
---@param lang string
---@return string[]
local function definition_patterns(name, lang)
  local js = {
    "function " .. name .. " $$$",
    "async function " .. name .. " $$$",
    "const " .. name .. " = $$$",
    "let " .. name .. " = $$$",
    "var " .. name .. " = $$$",
    "class " .. name .. " $$$",
  }
  local by_lang = {
    scala = {
      "def " .. name .. " $$$",
      "val " .. name .. " $$$",
      "var " .. name .. " $$$",
      "class " .. name .. " $$$",
      "object " .. name .. " $$$",
      "trait " .. name .. " $$$",
      "type " .. name .. " $$$",
      "given " .. name .. " $$$",
    },
    python = {
      "def " .. name .. " $$$",
      "async def " .. name .. " $$$",
      "class " .. name .. " $$$",
    },
    go = {
      "func " .. name .. " $$$",
      "func ($_) " .. name .. " $$$",
      "type " .. name .. " struct $$$",
      "type " .. name .. " interface $$$",
      "type " .. name .. " $$$",
    },
    rust = {
      "fn " .. name .. " $$$",
      "struct " .. name .. " $$$",
      "enum " .. name .. " $$$",
      "trait " .. name .. " $$$",
      "type " .. name .. " $$$",
      "const " .. name .. " $$$",
      "mod " .. name .. " $$$",
    },
    lua = {
      "function " .. name .. " $$$",
      "local function " .. name .. " $$$",
      "local " .. name .. " = $$$",
    },
    javascript = js,
    typescript = vim.list_extend(vim.deepcopy(js), {
      "type " .. name .. " = $$$",
      "interface " .. name .. " $$$",
      "enum " .. name .. " $$$",
    }),
    tsx = vim.list_extend(vim.deepcopy(js), {
      "type " .. name .. " = $$$",
      "interface " .. name .. " $$$",
      "enum " .. name .. " $$$",
    }),
    java = {
      "class " .. name .. " $$$",
      "interface " .. name .. " $$$",
      "enum " .. name .. " $$$",
      "$_ " .. name .. "($$$) { $$$ }",
    },
    kotlin = {
      "fun " .. name .. " $$$",
      "val " .. name .. " $$$",
      "var " .. name .. " $$$",
      "class " .. name .. " $$$",
      "object " .. name .. " $$$",
      "interface " .. name .. " $$$",
    },
    c = {
      "$_ " .. name .. "($$$) { $$$ }",
      "struct " .. name .. " $$$",
      "enum " .. name .. " $$$",
      "typedef $$$ " .. name,
    },
    cpp = {
      "$_ " .. name .. "($$$) { $$$ }",
      "class " .. name .. " $$$",
      "struct " .. name .. " $$$",
      "enum " .. name .. " $$$",
      "using " .. name .. " = $$$",
    },
    ruby = {
      "def " .. name .. " $$$",
      "class " .. name .. " $$$",
      "module " .. name .. " $$$",
    },
    php = {
      "function " .. name .. " $$$",
      "class " .. name .. " $$$",
      "interface " .. name .. " $$$",
    },
    csharp = {
      "class " .. name .. " $$$",
      "interface " .. name .. " $$$",
      "enum " .. name .. " $$$",
      "$_ " .. name .. "($$$) { $$$ }",
    },
    swift = {
      "func " .. name .. " $$$",
      "class " .. name .. " $$$",
      "struct " .. name .. " $$$",
      "enum " .. name .. " $$$",
      "protocol " .. name .. " $$$",
    },
    zig = {
      "fn " .. name .. " $$$",
      "const " .. name .. " = $$$",
      "var " .. name .. " = $$$",
    },
    elixir = {
      "def " .. name .. " $$$",
      "defp " .. name .. " $$$",
      "defmodule " .. name .. " $$$",
    },
    haskell = {
      name .. " :: $$$",
      name .. " $$$ = $$$",
    },
    solidity = {
      "function " .. name .. " $$$",
      "contract " .. name .. " $$$",
      "interface " .. name .. " $$$",
      "library " .. name .. " $$$",
    },
  }
  return by_lang[lang] or { name }
end

---@param name string
---@param call boolean
---@return string[]
local function usage_patterns(name, call)
  if call then
    -- Dot is optional: bare calls and method calls.
    return {
      name .. "($$$)",
      "$R." .. name .. "($$$)",
    }
  end
  return { name }
end

---@param matches table[]
---@param title string
local function open_sg_picker(matches, title)
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local entry_display = require "telescope.pickers.entry_display"

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 40 },
      { remaining = true },
    },
  }

  pickers
    .new({}, {
      prompt_title = title,
      initial_mode = "normal",
      finder = finders.new_table {
        results = matches,
        entry_maker = function(m)
          local rel = vim.fn.fnamemodify(m.file, ":.")
          local lnum = m.range.start.line + 1
          local col = m.range.start.column + 1
          local text = (m.text or ""):gsub("%s+", " ")
          return {
            value = m,
            filename = m.file,
            lnum = lnum,
            col = col,
            ordinal = string.format("%s:%d:%d:%s", rel, lnum, col, text),
            display = function()
              return displayer {
                { string.format("%s:%d:%d", rel, lnum, col), "TelescopeResultsLineNr" },
                { text, "TelescopeResultsIdentifier" },
              }
            end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      previewer = conf.grep_previewer {},
      mappings = require "mappings.telescope.defaults",
    })
    :find()
end

---@param patterns string[]
---@param lang string
---@param ext string|nil
---@return table[]|nil matches
local function sg_search(patterns, lang, ext)
  local bin = resolve_ast_grep()
  if not bin then
    notify.send(
      "ripgrelsp",
      "ast-grep not found (install CLI or put it in mason/bin)",
      vim.log.levels.WARN
    )
    return nil
  end

  local cmd = { bin, "run", "-l", lang, "--json=compact", "--color", "never" }
  if ext then
    table.insert(cmd, "--globs")
    table.insert(cmd, "*." .. ext)
  end
  for _, pattern in ipairs(patterns) do
    table.insert(cmd, "-p")
    table.insert(cmd, pattern)
  end
  table.insert(cmd, ".")

  local result = vim.system(cmd, { text = true, cwd = vim.fn.getcwd() }):wait()
  -- exit 1 = no matches for ast-grep
  if result.code ~= 0 and result.code ~= 1 then
    local err = vim.trim(result.stderr or result.stdout or "ast-grep failed")
    notify.send("ripgrelsp", err, vim.log.levels.ERROR)
    return nil
  end

  local stdout = vim.trim(result.stdout or "")
  if stdout == "" then
    return {}
  end

  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok then
    notify.send("ripgrelsp", "Failed to parse ast-grep JSON", vim.log.levels.ERROR)
    return nil
  end

  ---@type table[]
  local matches = decoded
  -- Deduplicate by file:line:col
  local seen = {}
  local unique = {}
  for _, m in ipairs(matches) do
    local key = string.format("%s:%d:%d", m.file, m.range.start.line, m.range.start.column)
    if not seen[key] then
      seen[key] = true
      unique[#unique + 1] = m
    end
  end
  return unique
end

---@param word? string
---@param patterns string[]
---@param title string
local function run_ast(word, patterns, title)
  local symbol = resolve_word(word)
  if not symbol then
    notify.send("ripgrelsp", "No word under cursor", vim.log.levels.WARN)
    return
  end

  local lang = current_sg_lang()
  if not lang then
    notify.send("ripgrelsp", "Unsupported filetype for ast-grep: " .. (vim.bo.filetype or ""), vim.log.levels.WARN)
    return
  end

  local ext = current_extension()
  local matches = sg_search(patterns, lang, ext)
  if matches == nil then
    return
  end
  if #matches == 0 then
    notify.send("ripgrelsp", "No ast-grep matches for " .. symbol, vim.log.levels.INFO)
    return
  end

  open_sg_picker(matches, title)
end

---Find definition via ast-grep structural patterns. Optional `word`; defaults to `<cword>`.
---@param word? string
function M.find_definition_ast(word)
  local symbol = resolve_word(word)
  if not symbol then
    notify.send("ripgrelsp", "No word under cursor", vim.log.levels.WARN)
    return
  end
  local lang = current_sg_lang()
  if not lang then
    notify.send("ripgrelsp", "Unsupported filetype for ast-grep: " .. (vim.bo.filetype or ""), vim.log.levels.WARN)
    return
  end
  run_ast(symbol, definition_patterns(symbol, lang), "sg definition: " .. symbol)
end

---Find usages via ast-grep. Calls use `name($$$)` / `$R.name($$$)`; else bare identifier.
---@param word? string
function M.find_usages_ast(word)
  local symbol = resolve_word(word)
  if not symbol then
    notify.send("ripgrelsp", "No word under cursor", vim.log.levels.WARN)
    return
  end
  run_ast(symbol, usage_patterns(symbol, is_call_site(symbol)), "sg usages: " .. symbol)
end

return M
