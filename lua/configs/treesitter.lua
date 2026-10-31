---@diagnostic disable-next-line: missing-fields
local treesitter = require "nvim-treesitter"
treesitter.setup {
  install_dir = vim.fn.stdpath "data" .. "/tree-sitter",
}

local wanted = {
  -- ===== General-Purpose & Systems Programming =====
  "c", -- C language
  "cpp", -- C++
  "rust", -- Rust
  "zig", -- Zig

  -- ===== JVM Ecosystem (as requested) =====
  "java",
  "kotlin",
  "scala",
  "clojure", -- JVM functional language

  -- ===== Web & Scripting =====
  "javascript",
  "typescript", -- TypeScript
  "tsx", -- TypeScript + JSX (React)
  "html",
  "css",
  "scss", -- SCSS/Sass

  -- ===== Backend & General =====
  "python",
  "go",
  "lua",
  "bash",
  "vim",

  -- ===== Functional & Multi-paradigm =====
  "haskell", -- Haskell
  "ocaml", -- OCaml
  "fsharp", -- F#
  "elixir", -- Elixir

  -- ===== Configuration & Data Formats =====
  "json",
  "yaml",
  "toml",
  "xml",
  "ini", -- .ini files
  "nix", -- Nix expressions

  -- ===== Documentation & Markup =====
  "markdown",
  "markdown_inline",
  "latex", -- LaTeX
  "rst", -- reStructuredText

  -- ===== Build & Infrastructure =====
  "dockerfile",
  "cmake", -- CMakeLists.txt
  "make", -- Makefiles

  -- ===== Version Control & Dev Tools =====
  "gitignore",
  "gitattributes",
  -- "gitcommit", -- Commit messages
  "git_rebase", -- Rebase files

  -- ===== Query & Specialized =====
  "sql", -- SQL
  "regex", -- Regular expressions
  "comment", -- For comment-based features

  "todotxt",
  "csv",

  "diff",
}

local M = {}
local attempted, queue = {}, {}
local running = false
local log = require "nvim-treesitter.log"
local state_path = vim.fn.stdpath "data" .. "/tree-sitter/auto-install.json"

-- This manifest is the parser list after its first creation. Entries may be
-- added/removed here without editing this module; failed installs retry next run.
local state
local read_ok, lines = pcall(vim.fn.readfile, state_path)
if read_ok then
  local ok, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if ok and type(decoded) == "table" and not vim.islist(decoded) then
    state = {}
    for lang, status in pairs(decoded) do
      if type(lang) == "string" and (status == "pending" or status == "installed" or status == "failed") then
        state[lang] = status
      end
    end
  else
    log.trace("Invalid automatic parser manifest: %s", state_path)
  end
end
if not state then
  state = {}
  for _, lang in ipairs(wanted) do
    state[lang] = "pending"
  end
end

local function save_state()
  local ok, err = pcall(function()
    vim.fn.mkdir(vim.fn.fnamemodify(state_path, ":h"), "p")
    local temporary = state_path .. "." .. vim.fn.getpid()
    assert(vim.fn.writefile({ vim.json.encode(state) }, temporary) == 0, "write failed")
    assert(vim.uv.fs_rename(temporary, state_path))
  end)
  if not ok then
    log.trace("Could not save automatic parser manifest: %s", tostring(err))
  end
end

-- Install one parser at a time: pcall catches launch errors, while the task's
-- callback reports asynchronous errors and unsuccessful compilation separately.
local function install_next()
  local lang = table.remove(queue, 1)
  if not lang then
    running = false
    return
  end
  local function finished(err, success)
    state[lang] = not err and success == true and "installed" or "failed"
    save_state()
    if state[lang] == "failed" then
      log.trace("Automatic parser install failed for %s: %s", lang, tostring(err or "installation unsuccessful"))
    end
    vim.schedule(install_next)
  end
  local ok, task = pcall(treesitter.install, { lang }, { summary = false })
  if ok and task then
    task:await(finished)
  else
    finished(task or "installation did not start")
  end
end

function M.install(languages)
  local available = {}
  for _, lang in ipairs(treesitter.get_available()) do
    available[lang] = true
  end
  local installed = {}
  for _, lang in ipairs(treesitter.get_installed "parsers") do
    installed[lang] = true
  end
  local parsers = require "nvim-treesitter.parsers"
  local seen = {}
  local function add(lang)
    if
      not available[lang]
      or seen[lang]
      or (parsers[lang] and parsers[lang].tier == 4)
    then
      return
    end
    seen[lang] = true
    for _, dependency in ipairs((parsers[lang] or {}).requires or {}) do
      add(dependency)
    end
    if installed[lang] then
      state[lang] = "installed"
    elseif not attempted[lang] then
      attempted[lang] = true
      state[lang] = "pending"
      queue[#queue + 1] = lang
    end
  end
  for _, lang in ipairs(languages) do
    add(lang)
  end
  save_state()
  if not running and #queue > 0 then
    running = true
    install_next()
  end
end

-- A parser or indentation query may be absent while an install is pending/failed.
function M.indentexpr()
  local ok, indent = pcall(treesitter.indentexpr)
  return ok and indent or -1
end

local languages = vim.tbl_keys(state)
table.sort(languages)
M.install(languages)

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("TreesitterBestEffortInstall", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if lang then
      M.install { lang }
    end
  end,
})

return M
