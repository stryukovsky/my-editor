local M = {}
function M.hunks(buf)
  local cache = require "mini.diff.hunks_cache"
  if cache.untracked._read(buf, "eligible") then
    return {}
  end
  return cache.unstaged._read(buf, "hunks") or {}
end
return M
