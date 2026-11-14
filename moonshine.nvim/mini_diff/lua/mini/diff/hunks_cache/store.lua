-- One session-local store per kind. Only the engine bridge uses _read/_write;
-- public consumers receive independent snapshots and generation-checked writes.
local M = {}

function M.new()
  local entries, tokens = {}, {}
  local store = {}
  function store.get(buf)
    return vim.deepcopy(entries[buf])
  end
  function store.state(buf)
    local entry = entries[buf]
    if not entry then
      return
    end
    local state = entry.state or entry
    return { status = state.status, reason = state.reason }
  end
  function store.begin(buf, version)
    local token = {
      version = vim.deepcopy(version or {}),
      path = vim.api.nvim_buf_get_name(buf),
    }
    tokens[buf] = token
    return token
  end
  function store.publish(buf, token, snapshot)
    if tokens[buf] ~= token or not vim.api.nvim_buf_is_valid(buf) then
      return false
    end
    if vim.api.nvim_buf_get_name(buf) ~= token.path then
      return false
    end
    local version = token.version
    if
      version.changedtick
      and vim.api.nvim_buf_get_changedtick(buf) ~= version.changedtick
    then
      return false
    end
    if
      version.saved_revision
      and require("mini.diff.hunks_loader").saved_revision(token.path)
        ~= version.saved_revision
    then
      return false
    end
    entries[buf] = vim.deepcopy(snapshot)
    entries[buf].version = vim.deepcopy(version)
    return true
  end
  function store.invalidate(buf, reason)
    tokens[buf] = nil
    entries[buf] = { status = "unavailable", reason = reason, hunks = {} }
  end
  function store.clear(buf)
    entries[buf], tokens[buf] = nil, nil
  end
  function store._read(buf, field)
    local entry = entries[buf]
    if not entry then
      return
    end
    if field then
      return entry[field]
    end
    return entry
  end
  function store._write(buf, field, value)
    entries[buf] = entries[buf] or {}
    entries[buf][field] = value
  end
  return store
end

return M
