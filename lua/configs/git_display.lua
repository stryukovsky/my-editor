-- Shared git row formatting for Telescope pickers.

local pretty_date = require "utils.pretty_date"
local git = require "configs.gitutils"

local M = {}

M.ELLIPSIS = "…"
M.COMMIT_SUBJECT_MAX = 60

local SLASH_SHORTEN = {
  [0] = { n = 35, keep = 16 },
  [1] = { n = 30, keep = 8 },
  [2] = { n = 15, keep = 4 },
}

---@param name string
---@return string
function M.shorten_author(name)
  name = vim.trim(name or ""):gsub("%s+", " ")
  if name == "" then
    return ""
  end

  if name:find " " then
    local parts = vim.split(name, " ", { plain = true, trimempty = true })
    local first = parts[1]
    local last = parts[#parts]
    return vim.fn.strcharpart(first, 0, 2) .. ". " .. vim.fn.strcharpart(last, 0, 3) .. "."
  end

  local len = vim.fn.strchars(name)
  if len <= 3 then
    return name
  end
  return vim.fn.strcharpart(name, 0, 3) .. ".." .. vim.fn.strcharpart(name, len - 3, 3)
end

---@param slash_count integer
---@return { n: integer, keep: integer }
local function slash_shorten_rule(slash_count)
  return SLASH_SHORTEN[slash_count] or { n = 9, keep = 2 }
end

---@param component string
---@param n integer
---@param keep integer
---@return string
local function shorten_slash_component(component, n, keep)
  local len = vim.fn.strchars(component)
  if len <= n then
    return component
  end
  return vim.fn.strcharpart(component, 0, keep) .. M.ELLIPSIS .. vim.fn.strcharpart(component, len - keep, keep)
end

-- Shorten each `/` segment of a local or remote branch name.
---@param name string
---@return string
function M.shorten_branch_name(name)
  if name == "" then
    return name
  end
  local slash_count = select(2, name:gsub("/", ""))
  local rule = slash_shorten_rule(slash_count)
  local parts = vim.split(name, "/", { plain = true })
  for i, part in ipairs(parts) do
    parts[i] = shorten_slash_component(part, rule.n, rule.keep)
  end
  return table.concat(parts, "/")
end

---@param subject string
---@return string
function M.truncate_subject(subject)
  if vim.fn.strchars(subject) <= M.COMMIT_SUBJECT_MAX then
    return subject
  end
  return vim.fn.strcharpart(subject, 0, M.COMMIT_SUBJECT_MAX) .. M.ELLIPSIS
end

---@param upstream string origin/main
---@param trackshort string "=" | "<" | ">" | "<>" | ""
---@param remotename string origin
---@return string text
---@return string hl
function M.tracking_display(upstream, trackshort, remotename)
  if upstream == "" then
    return "", "TelescopeResultsComment"
  end
  if trackshort == "=" then
    local remote = remotename ~= "" and remotename or (upstream:match "^([^/]+)" or upstream)
    return "= " .. remote, "TelescopeResultsComment"
  end
  return "=> " .. upstream, "TelescopeResultsIdentifier"
end

---@class git_display.Branch
---@field head string
---@field name string
---@field display_name string
---@field authorname string
---@field tracking string
---@field track_hl string
---@field committerdate string
---@field committer_ts integer|nil
---@field refname string
---@field upstream string

---@param cwd? string
---@param opts? { pattern?: string, show_remote_tracking_branches?: boolean }
---@return git_display.Branch[]
---@return string|nil err
function M.list_branches(cwd, opts)
  opts = opts or {}
  local format =
    "%(HEAD)%00%(refname)%00%(authorname)%00%(upstream:lstrip=2)%00%(upstream:trackshort)%00%(upstream:remotename)%00%(committerdate:unix)"
  local args = { "for-each-ref", "--format", format, "--sort", "-committerdate" }
  if opts.pattern then
    args[#args + 1] = opts.pattern
  end

  local out, err = git.run(args, cwd)
  if not out then
    return {}, err or "git for-each-ref failed"
  end

  local show_remote = opts.show_remote_tracking_branches
  if show_remote == nil then
    show_remote = true
  end
  local now = os.time()
  local results = {}

  for line in vim.gsplit(out, "\n", { trimempty = true }) do
    local fields = vim.split(line, "\0", { plain = true })
    local raw_ref = fields[2] or ""
    local prefix
    if vim.startswith(raw_ref, "refs/remotes/") then
      if show_remote then
        prefix = "refs/remotes/"
      end
    elseif vim.startswith(raw_ref, "refs/heads/") then
      prefix = "refs/heads/"
    end
    if prefix then
      local upstream = fields[4] or ""
      local tracking, track_hl = M.tracking_display(upstream, fields[5] or "", fields[6] or "")
      local ts = tonumber(fields[7])
      local name = raw_ref:sub(#prefix + 1)
      local entry = {
        head = fields[1] or "",
        refname = raw_ref,
        authorname = M.shorten_author(fields[3] or ""),
        upstream = upstream,
        tracking = tracking,
        track_hl = track_hl,
        committer_ts = ts,
        committerdate = ts and pretty_date(ts, now) or "",
        name = name,
        display_name = M.shorten_branch_name(name),
      }
      local index = entry.head == "*" and 1 or (#results + 1)
      table.insert(results, index, entry)
    end
  end

  return results, nil
end

---@param results git_display.Branch[]
---@return table<string, integer>
function M.branch_widths(results)
  local strings = require "plenary.strings"
  local widths = {
    name = 0,
    authorname = 0,
    tracking = 0,
    committerdate = 0,
  }
  for _, entry in ipairs(results) do
    for key, value in pairs(widths) do
      local text = key == "name" and entry.display_name or entry[key]
      widths[key] = math.max(value, strings.strdisplaywidth(text or ""))
    end
  end
  return widths
end

---@param widths table<string, integer>
---@return fun(entry: git_display.Branch): table
function M.branch_displayer(widths)
  local entry_display = require "telescope.pickers.entry_display"
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 1 },
      { width = widths.name },
      { width = widths.authorname },
      { width = widths.tracking },
      { width = widths.committerdate },
    },
  }
  return function(entry)
    return displayer {
      { entry.head },
      { entry.display_name, "TelescopeResultsIdentifier" },
      { entry.authorname, "TelescopeResultsComment" },
      { entry.tracking, entry.track_hl },
      { entry.committerdate, "TelescopeResultsComment" },
    }
  end
end

return M
