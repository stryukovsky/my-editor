-- Ripgrep-backed "LSP-ish" navigation for heavy projects.
-- Uses telescope live_grep, scoped to the current file extension.
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
    notify.send("ripgreplsp", "No word under cursor", vim.log.levels.WARN)
    return
  end

  local ext = current_extension()
  if not ext then
    notify.send("ripgreplsp", "Current buffer has no file extension", vim.log.levels.WARN)
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
    notify.send("ripgreplsp", "No word under cursor", vim.log.levels.WARN)
    return
  end

  local ext = current_extension()
  if not ext then
    notify.send("ripgreplsp", "Current buffer has no file extension", vim.log.levels.WARN)
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

return M
