local M = {}
function M.hunks(buf)
  local cache = require "mini.diff.hunks_cache.untracked"
  return cache._read(buf, "eligible") and cache._read(buf, "hunks") or {}
end
return M
