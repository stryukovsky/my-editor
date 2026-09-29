-- Shared Telescope *preview pane* for git pickers (the right-hand window).
--
-- Result rows (hash, author, date, truncated subject) live in `display`.
-- This module only renders the preview: run git async, debounce fast scrolling,
-- cancel the previous job so a skipped entry never paints.
--
-- Ready-made previewers:
--   branch_log   — graph log of a branch   (<A-g> pretty branch picker)
--   commit_diff  — `git show` patch        (<A-c> pretty commits; MiniDiff history)
--   oneline_log  — short log of a ref      (MiniDiff review ref picker)
--
-- Or call `new_buffer_previewer` with your own `cmd` / `format` / `highlight`.

local display = require "telescope_pretty_git.display"

local M = {}

local DEBOUNCE_MS = 80
local BRANCH_LOG_COUNT = 80
local ONELINE_COUNT = 40
local LOG_SEP = "\1"
local preview_ns = vim.api.nvim_create_namespace "telescope_pretty_git.preview.log"

-- git log --graph line: `<graph><hash>\1<decorations>\1<subject>\1<relative date>`
---@param line string
---@return string
local function format_log_line(line)
  local graph, hash, payload = line:match("^(.-)([0-9a-fA-F]+)" .. LOG_SEP .. "(.*)$")
  if not hash then
    return line
  end
  local parts = vim.split(payload, LOG_SEP, { plain = true })
  local deco = vim.trim(parts[1] or "")
  local subject = display.truncate_subject(parts[2] or "", 60)
  local date = parts[3] or ""
  if deco ~= "" then
    return string.format("%s%s - %s %s (%s)", graph, hash, deco, subject, date)
  end
  return string.format("%s%s - %s (%s)", graph, hash, subject, date)
end

---@param bufnr integer
---@param content string[]
local function highlight_log_buffer(bufnr, content)
  local hl = vim.hl
  vim.api.nvim_buf_clear_namespace(bufnr, preview_ns, 0, -1)
  for i = 1, #content do
    local line = content[i]
    local hstart, hend = line:find "[0-9a-fA-F]+"
    if hstart and hend < #line then
      pcall(hl.range, bufnr, preview_ns, "TelescopeResultsIdentifier", { i - 1, hstart - 1 }, { i - 1, hend })
    end
    local _, cstart = line:find "- %("
    if cstart then
      local cend = string.find(line, "%) ")
      if cend then
        pcall(hl.range, bufnr, preview_ns, "TelescopeResultsConstant", { i - 1, cstart - 1 }, { i - 1, cend })
      end
    end
    local dstart = line:find " %(%d"
    if dstart then
      pcall(hl.range, bufnr, preview_ns, "TelescopeResultsSpecialComment", { i - 1, dstart }, { #line })
    end
  end
end

-- Treesitter highlight is costly on huge patches; fall back to regex syntax.
---@param bufnr integer
---@param lines string[]
---@param ft string
local function highlight_ft(bufnr, lines, ft)
  local putils = require "telescope.previewers.utils"
  if #lines > 400 then
    vim.bo[bufnr].syntax = ft
    return
  end
  putils.highlighter(bufnr, ft, {})
end

---@class telescope_pretty_git.preview.Spec
---@field title string
---@field cwd string
---@field cmd fun(entry: table): string[]
---@field bufname fun(entry: table): string
---@field format? fun(lines: string[]): string[]
---@field highlight? fun(bufnr: integer, lines: string[])

--- One Telescope buffer previewer. `seq` is a generation counter: each new
--- selection increments it; delayed git callbacks with an old id are ignored.
---@param spec telescope_pretty_git.preview.Spec
---@return table
function M.new_buffer_previewer(spec)
  local previewers = require "telescope.previewers"
  local seq = 0
  ---@type vim.SystemObj|nil
  local proc
  ---@type uv.uv_timer_t|nil
  local timer

  local function stop_timer()
    if not timer then
      return
    end
    local t = timer
    timer = nil
    pcall(function()
      t:stop()
      t:close()
    end)
  end

  local function kill_proc()
    if not proc then
      return
    end
    local p = proc
    proc = nil
    pcall(function()
      p:kill "sigterm"
    end)
  end

  return previewers.new_buffer_previewer {
    title = spec.title,
    teardown = function()
      seq = seq + 1
      stop_timer()
      kill_proc()
    end,
    get_buffer_by_name = function(_, entry)
      return spec.bufname(entry)
    end,
    define_preview = function(self, entry)
      -- Drop the last git job immediately; wait DEBOUNCE_MS in case the user
      -- keeps moving. Only then start a new process.
      seq = seq + 1
      local id = seq
      local bufnr = self.state.bufnr
      kill_proc()
      stop_timer()

      timer = vim.uv.new_timer()
      timer:start(
        DEBOUNCE_MS,
        0,
        vim.schedule_wrap(function()
          if id ~= seq then
            return
          end
          stop_timer()
          proc = vim.system(spec.cmd(entry), { text = true, cwd = spec.cwd }, function(result)
            vim.schedule(function()
              if id ~= seq then
                return
              end
              proc = nil
              if not vim.api.nvim_buf_is_valid(bufnr) then
                return
              end
              local stdout = result.stdout or ""
              local lines = vim.split(stdout, "\n", { plain = true, trimempty = true })
              if spec.format then
                lines = spec.format(lines)
              end
              if #lines == 0 then
                local err = vim.trim(result.stderr or "")
                lines = { err ~= "" and err or "No preview" }
              end
              vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
              if spec.highlight then
                spec.highlight(bufnr, lines)
              end
            end)
          end)
        end)
      )
    end,
  }
end

--- Graph log of `entry.value` (branch name or ref). Used by the pretty branch picker.
---@param opts { cwd: string }
---@return table
function M.branch_log(opts)
  return M.new_buffer_previewer {
    title = "Git Branch Preview",
    cwd = opts.cwd,
    bufname = function(entry)
      return entry.value
    end,
    cmd = function(entry)
      return {
        "git",
        "-C",
        opts.cwd,
        "--no-pager",
        "log",
        "--graph",
        "--max-count=" .. tostring(BRANCH_LOG_COUNT),
        "--pretty=format:%h%x01%d%x01%s%x01%cr",
        "--abbrev-commit",
        "--date=relative",
        entry.value,
      }
    end,
    format = function(lines)
      local out = {}
      for i, line in ipairs(lines) do
        out[i] = format_log_line(line)
      end
      return out
    end,
    highlight = highlight_log_buffer,
  }
end

--- `git show` of `entry.value` (commit or branch tip). Pretty commits + MiniDiff history.
---@param opts { cwd: string }
---@return table
function M.commit_diff(opts)
  return M.new_buffer_previewer {
    title = "Diff to parent",
    cwd = opts.cwd,
    bufname = function(entry)
      return entry.value
    end,
    cmd = function(entry)
      return {
        "git",
        "-C",
        opts.cwd,
        "--no-pager",
        "show",
        "--stat",
        "-p",
        "--format=medium",
        entry.value,
      }
    end,
    highlight = function(bufnr, lines)
      highlight_ft(bufnr, lines, "diff")
    end,
  }
end

--- Short log of `entry.value`. MiniDiff review ref picker (branches, tags, commits).
---@param opts { cwd: string }
---@return table
function M.oneline_log(opts)
  return M.new_buffer_previewer {
    title = "Ref log",
    cwd = opts.cwd,
    bufname = function(entry)
      return entry.value
    end,
    cmd = function(entry)
      return {
        "git",
        "-C",
        opts.cwd,
        "--no-pager",
        "log",
        "--oneline",
        "-n",
        tostring(ONELINE_COUNT),
        entry.value,
      }
    end,
    highlight = function(bufnr, lines)
      highlight_ft(bufnr, lines, "gitcommit")
    end,
  }
end

return M
