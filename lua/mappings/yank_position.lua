local map = require "mappings.map"
local notify = require "configs.notify"
local is_normal_buffer = require "utils.is_normal_buffer"
local gitutils = require "configs.gitutils"

---@param buf? integer
---@return { rel: string|nil, abs: string }|nil
local function current_file(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if vim.b[buf].minidiff_review then
    local session = require("configs.minidiff_review").session()
    if not session then
      return nil
    end
    for path, handle in pairs(session.buffers) do
      if handle == buf then
        return {
          rel = path,
          abs = vim.fs.normalize(session.cwd .. "/" .. path),
        }
      end
    end
    return nil
  end

  if buf == vim.api.nvim_get_current_buf() then
    if not is_normal_buffer() then
      return nil
    end
  else
    if vim.b[buf].large_hunk_viewer or vim.bo[buf].buftype ~= "" or not vim.bo[buf].buflisted then
      return nil
    end
    if vim.api.nvim_buf_get_name(buf) == "" then
      return nil
    end
  end

  local abs = vim.fs.normalize(vim.api.nvim_buf_get_name(buf))
  if abs == "" then
    return nil
  end

  local root = gitutils.root(vim.fn.fnamemodify(abs, ":h"))
  local rel = root and gitutils.relpath(abs, root) or nil
  if rel == "." then
    rel = nil
  end
  return { rel = rel, abs = abs }
end

---@param text string
local function yank(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg('"', text)
  notify.replace("yank.position", "Yank", text, vim.log.levels.INFO)
end

local function require_file()
  local file = current_file()
  if not file then
    notify.send("Yank", "Not a normal or review file", vim.log.levels.WARN)
    return nil
  end
  return file
end

map("n", "<leader>yf", function()
  local file = require_file()
  if not file then
    return
  end
  if not file.rel then
    notify.send("Yank", "Not in a git repository", vim.log.levels.WARN)
    return
  end
  yank(file.rel)
end, { desc = "yank repo-relative file path" })

map("n", "<leader>yp", function()
  local file = require_file()
  if not file then
    return
  end
  if not file.rel then
    notify.send("Yank", "Not in a git repository", vim.log.levels.WARN)
    return
  end
  yank(string.format("%s:%d", file.rel, vim.fn.line "."))
end, { desc = "yank repo-relative path:line" })

map("n", "<leader>yF", function()
  local file = require_file()
  if file then
    yank(file.abs)
  end
end, { desc = "yank absolute file path" })

local TODO_PAT = "%f[%w]TODO%f[%W]"

---@return string|nil
local function repo_root()
  local file = current_file()
  if file and file.abs then
    local root = gitutils.root(vim.fn.fnamemodify(file.abs, ":h"))
    if root then
      return root
    end
  end
  return gitutils.root()
end

---@param line string
---@return string|nil path
---@return boolean deleted
local function diff_plus_file(line)
  if not line:find("^%+%+%+ ") then
    return nil, false
  end
  local path = line:match("^%+%+%+ b/(.+)$") or line:match("^%+%+%+ (.+)$")
  if not path then
    return nil, false
  end
  path = path:gsub("\t.*$", "")
  if path == "/dev/null" or path == "b/dev/null" then
    return nil, true
  end
  return path, false
end

---@param diff string
---@param seen table<string, boolean>
---@param items string[]
local function collect_diff_todos(diff, seen, items)
  local rel
  local new_lnum
  for line in vim.gsplit(diff, "\n", { plain = true }) do
    local plus_file, deleted = diff_plus_file(line)
    if deleted then
      rel, new_lnum = nil, nil
    elseif plus_file then
      rel = plus_file
      new_lnum = nil
    else
      local plus = line:match("^@@ %-[^ ]+ %+([^ ]+) @@")
      if plus then
        new_lnum = tonumber((plus:match("^(%d+)")))
      elseif rel and new_lnum and line:sub(1, 1) == "+" and line:sub(1, 3) ~= "+++" then
        if line:sub(2):find(TODO_PAT) then
          local key = string.format("%s:%d", rel, new_lnum)
          if not seen[key] then
            seen[key] = true
            items[#items + 1] = key
          end
        end
        new_lnum = new_lnum + 1
      end
    end
  end
end

---@return string[]|nil
local function todo_locations()
  local root = repo_root()
  if not root then
    return nil
  end
  local items, seen = {}, {}
  collect_diff_todos(select(1, gitutils.diff({ "diff", "-U0", "--no-color", "--no-ext-diff" }, root)) or "", seen, items)
  collect_diff_todos(
    select(1, gitutils.diff({ "diff", "--cached", "-U0", "--no-color", "--no-ext-diff" }, root)) or "",
    seen,
    items
  )
  table.sort(items)
  return items
end

map("n", "<leader>yt", function()
  local items = todo_locations()
  if not items then
    notify.send("Yank", "Not in a git repository", vim.log.levels.WARN)
    return
  end
  if #items == 0 then
    notify.send("Yank", "No TODOs in uncommitted changes", vim.log.levels.INFO)
    return
  end
  yank("TODOs:\n" .. table.concat(items, "\n"))
end, { desc = "yank TODOs from uncommitted git hunks" })
