local M = {}

function M.load(read, cwd, basename, current, callback)
  read({ "show", ":0:./" .. basename }, cwd, function(code, text, err)
    if not current() then
      return
    end
    if code == 0 or err then
      return callback(code, text, err, false)
    end
    require("mini.diff.hunks_loader.untracked").load(
      read,
      cwd,
      basename,
      current,
      callback
    )
  end)
end

function M.from_indices(indices)
  local hunks, summary, last_to =
    {}, { add = 0, change = 0, delete = 0, n_ranges = 0 }, -math.huge
  for _, d in ipairs(indices) do
    local old, new = d[2], d[4]
    hunks[#hunks + 1] = {
      ref_start = d[1],
      ref_count = old,
      buf_start = d[3],
      buf_count = new,
      type = old == 0 and "add" or (new == 0 and "delete" or "change"),
    }
    local changed = math.min(old, new)
    summary.add, summary.change, summary.delete =
      summary.add + new - changed,
      summary.change + changed,
      summary.delete + old - changed
    local from = math.max(d[3], 1)
    summary.n_ranges = summary.n_ranges + (from <= last_to + 1 and 0 or 1)
    last_to = math.max(last_to, from + math.max(new, 1) - 1)
  end
  return hunks, summary
end

function M.compute(reference, text, opts)
  local indices = vim.diff(reference, text, opts)
  local hunks, summary = M.from_indices(indices)
  return { indices = indices, hunks = hunks, summary = summary }
end

return M
