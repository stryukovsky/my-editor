-- Normal-mode `y` for Telescope: yank the useful identifier of the current
-- (or multi-selected) entry. Keeps the picker open.

local action_state = require "telescope.actions.state"
local notify = require "configs.notify"

local M = {}

local SKIP_PROMPT = {
  undo = true,
  ["undo history"] = true,
  ["yank history"] = true,
}

---@param text string
local function set_clipboard(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
end

---@param entry table
---@return boolean
local function is_commit(entry)
  local value = entry.value
  local short = entry.short
  return type(short) == "string" and short ~= "" and type(value) == "string" and value:match "^%x+$" ~= nil and #value >= 7
end

---@param path string
---@param cwd? string
---@return string
local function absolutize(path, cwd)
  path = vim.fs.normalize(path)
  if path:sub(1, 1) == "/" then
    return path:gsub("/$", "")
  end
  local root = cwd and vim.fs.normalize(cwd) or vim.fs.normalize(vim.uv.cwd() or ".")
  return vim.fs.normalize(root .. "/" .. path):gsub("/$", "")
end

---@param entry table
---@param picker table
---@return string|nil
local function entry_text(entry, picker)
  if not entry then
    return nil
  end

  -- Pretty git commits (and MiniDiff history): full hash.
  if is_commit(entry) then
    return entry.value
  end

  -- Pretty git branches.
  if type(entry.name) == "string" and entry.name ~= "" then
    return entry.name
  end

  -- Templates picker.
  if type(entry.destination) == "string" and entry.destination ~= "" then
    return entry.destination
  end

  -- Projects picker: value = { path = "...", tab = ... }.
  if type(entry.value) == "table" and type(entry.value.path) == "string" and entry.value.path ~= "" then
    return absolutize(entry.value.path)
  end

  local path = entry.path or entry.filename
  if type(path) == "string" and path ~= "" then
    local cwd = entry.cwd or picker.cwd
    local abs = absolutize(path, cwd)
    if entry.lnum then
      if entry.col then
        return string.format("%s:%d:%d", abs, entry.lnum, entry.col)
      end
      return string.format("%s:%d", abs, entry.lnum)
    end
    return abs
  end

  if type(entry.value) == "string" and entry.value ~= "" then
    return entry.value
  end

  return nil
end

---@param prompt_bufnr integer
function M.yank_selection(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  if not picker then
    return
  end

  local title = type(picker.prompt_title) == "string" and picker.prompt_title:lower() or ""
  if SKIP_PROMPT[title] then
    return
  end

  local multi = picker:get_multi_selection()
  local entries = #multi > 0 and multi or { action_state.get_selected_entry() }

  local parts = {}
  for _, entry in ipairs(entries) do
    local text = entry_text(entry, picker)
    if text and text ~= "" then
      parts[#parts + 1] = text
    end
  end

  if #parts == 0 then
    return
  end

  local text = table.concat(parts, "\n")
  set_clipboard(text)
  notify.replace("telescope.yank", "Yank", text)
end

return M
