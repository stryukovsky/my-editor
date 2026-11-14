local M = {}

function M.range(hunk)
  local from = math.max(hunk.buf_start, 1)
  return from, from + math.max(hunk.buf_count, 1) - 1
end

function M.contiguous(hunks)
  local ranges = {}
  for _, hunk in ipairs(hunks) do
    local from, to = M.range(hunk)
    ranges[#ranges + 1] = { from = from, to = to }
  end
  table.sort(ranges, function(a, b)
    return a.from < b.from
  end)
  local result = {}
  for _, range in ipairs(ranges) do
    local previous = result[#result]
    if previous and range.from <= previous.to + 1 then
      previous.to = math.max(previous.to, range.to)
    else
      result[#result + 1] = range
    end
  end
  return result
end

function M.ranges(buf)
  local effective = require("mini.diff.navigation.unstaged").hunks(buf)
  local saved, unsaved =
    require("mini.diff.navigation.unsaved").partition(buf, effective)
  local hunks = {}
  vim.list_extend(hunks, saved)
  vim.list_extend(hunks, unsaved)
  vim.list_extend(hunks, require("mini.diff.navigation.untracked").hunks(buf))
  vim.list_extend(hunks, require("mini.diff.navigation.staged").hunks(buf))
  return M.contiguous(hunks)
end

function M.position(buf, line)
  local ranges = M.ranges(buf)
  for i, range in ipairs(ranges) do
    if range.from <= line and line <= range.to then
      return #ranges, i
    end
  end
  return #ranges
end

function M.iterate(ranges, direction, opts)
  local n, initial = #ranges, 0
  if direction == "first" then
    initial = 0
  end
  if direction == "last" then
    initial = n + 1
  end
  if direction == "next" then
    for i = n, 1, -1 do
      if ranges[i].from <= opts.line_start then
        initial = i
        break
      end
    end
  end
  if direction == "prev" then
    initial = n + 1
    for i = 1, n do
      if opts.line_start <= ranges[i].to then
        initial = i
        break
      end
    end
  end
  local edge = (direction == "prev" and initial == 1)
    or (direction == "next" and initial == n)
  if not opts.wrap and edge then
    return nil
  end
  local forward = direction == "first" or direction == "next"
  local index = initial + opts.n_times * (forward and 1 or -1)
  local wrapped = opts.wrap and (index < 1 or n < index)
  index = opts.wrap and ((index - 1) % n + 1) or math.min(math.max(index, 1), n)
  return index, wrapped
end

function M.move(ranges, direction, opts, notify)
  if #ranges == 0 then
    return notify("No hunks to go to", "INFO")
  end
  local index, wrapped = M.iterate(ranges, direction, opts)
  if not index then
    return notify(
      "No hunk ranges in direction " .. vim.inspect(direction),
      "INFO"
    )
  end
  if wrapped then
    notify(
      "Wrapped around edge in direction " .. vim.inspect(direction),
      "INFO"
    )
  end
  vim.cmd [[normal! m']]
  local line = ranges[index].from
  local _, col = vim.fn.getline(line):find "^%s*"
  vim.api.nvim_win_set_cursor(0, { line, col })
  vim.cmd "normal! zv"
end

function M.statusline()
  local diff = require "mini.diff"
  local state = diff.get_buf_state(0)
  if state and (state.status == "loading" or state.status == "updating") then
    return "diff: " .. state.status .. "…"
  end
  if not state or state.status ~= "ready" then
    return ""
  end
  local staged = diff.get_staged_state(0)
  if staged and staged.status ~= "ready" then
    return "staged: "
      .. staged.status
      .. (
        (staged.status == "loading" or staged.status == "updating") and "…"
        or ""
      )
  end
  local total, index = M.position(
    vim.api.nvim_get_current_buf(),
    vim.api.nvim_win_get_cursor(0)[1]
  )
  if total == 0 then
    return ""
  end
  return index and string.format("hunks: %d/%d", index, total)
    or string.format("hunks: %d", total)
end

function M.nav(direction)
  if vim.wo.diff then
    vim.cmd.normal { direction > 0 and "]c" or "[c", bang = true }
    vim.cmd "normal! zz"
    return
  end
  local diff = require "mini.diff"
  diff.flush_buf_diff(0)
  if
    not require("moonshine.diff.assure_git_hunks_are_ready").ready(0, true)
  then
    return
  end
  if direction > 0 then
    local total, index = M.position(
      vim.api.nvim_get_current_buf(),
      vim.api.nvim_win_get_cursor(0)[1]
    )
    if index and index == total then
      local notify = require "integrations.notify"
      if vim.b.minidiff_review then
        notify.send(
          "MiniDiff",
          "Last hunk, focusing review file list",
          vim.log.levels.INFO
        )
        require("moonshine.diff.review").focus_list()
      else
        notify.send(
          "MiniDiff",
          "Last hunk, focusing Neo-tree git status",
          vim.log.levels.INFO
        )
        require "moonshine.utils.ui_prevent_mess"()
        require "moonshine.utils.focus_neotree"("git_status", false, {})
      end
      return
    end
  end
  diff.goto_hunk(direction > 0 and "next" or "prev", { staged = true })
  vim.cmd "normal! zz"
end

return M
