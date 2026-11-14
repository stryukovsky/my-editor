local M = {
  staged = require "mini.diff.hunks_cache.staged",
  unstaged = require "mini.diff.hunks_cache.unstaged",
  unsaved = require "mini.diff.hunks_cache.unsaved",
  untracked = require "mini.diff.hunks_cache.untracked",
}
local kinds = { "staged", "unstaged", "unsaved", "untracked" }
local effective_fields = {
  hunks = true,
  ref_text = true,
  summary = true,
  has_result = true,
  ref_pending = true,
  ref_error = true,
}

function M.clear(buf)
  for _, kind in ipairs(kinds) do
    M[kind].clear(buf)
  end
end

function M.invalidate(buf, reason)
  for _, kind in ipairs(kinds) do
    M[kind].invalidate(buf, reason)
  end
end

-- Legacy engine records contain attachment/render bookkeeping only. Data fields
-- are views into the authoritative kind stores, not duplicate mutable caches.
function M.attachment(buf, existing)
  if existing then
    return existing
  end
  M.clear(buf)
  return setmetatable({ path = vim.api.nvim_buf_get_name(buf) }, {
    __index = function(_, field)
      if effective_fields[field] then
        return M.unstaged._read(buf, field)
      end
    end,
    __newindex = function(record, field, value)
      if effective_fields[field] then
        M.unstaged._write(buf, field, value)
      else
        rawset(record, field, value)
      end
    end,
  })
end

function M.git_attachment(buf)
  M.staged.clear(buf)
  return setmetatable({}, {
    __index = function(_, field)
      if field == "staged" then
        return M.staged._read(buf)
      end
    end,
    __newindex = function(record, field, value)
      if field == "staged" then
        M.staged.clear(buf)
        if value then
          for key, item in pairs(value) do
            M.staged._write(buf, key, item)
          end
        end
      else
        rawset(record, field, value)
      end
    end,
  })
end

function M.states_adapter()
  return setmetatable({}, {
    __index = function(_, buf)
      return M.unstaged._read(buf, "state")
    end,
    __newindex = function(_, buf, state)
      M.unstaged._write(buf, "state", state)
    end,
  })
end

return M
