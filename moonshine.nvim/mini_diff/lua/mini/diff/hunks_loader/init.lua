local M = {}
local cache = require "mini.diff.hunks_cache"
local uv = vim.uv or vim.loop

function M.saved_revision(path)
  local stat, err = uv.fs_stat(path)
  if not stat then
    return err and err:find("ENOENT", 1, true) and "missing"
      or (err or "unavailable")
  end
  return table.concat({
    stat.dev,
    stat.ino,
    stat.size,
    stat.mtime.sec,
    stat.mtime.nsec,
    stat.ctime.sec,
    stat.ctime.nsec,
  }, ":")
end

local function read_saved(path, new_path)
  local revision = M.saved_revision(path)
  if revision == "missing" then
    return {
      revision = revision,
      status = new_path and "ready" or "unavailable",
      text = new_path and "" or nil,
      reason = not new_path and "Saved file is absent" or nil,
    }
  end
  local file, err = io.open(path, "rb")
  if not file then
    return { revision = revision, status = "failed", reason = err }
  end
  local text, read_err = file:read "*a"
  file:close()
  if not text or M.saved_revision(path) ~= revision then
    return {
      revision = revision,
      status = "unavailable",
      reason = read_err or "Saved file changed during read",
    }
  end
  text = text:gsub("\r\n", "\n")
  if text ~= "" and text:sub(-1) ~= "\n" then
    text = text .. "\n"
  end
  return { revision = revision, status = "ready", text = text }
end

-- Pure raw layers supply provenance. Only index -> buffer is the effective
-- nonstaged diff: disk and buffer edits which cancel never add navigation stops.
function M.capture(buf, text, opts)
  local path = vim.api.nvim_buf_get_name(buf)
  local version = {
    changedtick = vim.api.nvim_buf_get_changedtick(buf),
    saved_revision = M.saved_revision(path),
    reference_request = cache.unstaged._read(buf, "reference_request"),
  }
  local eligible = cache.untracked._read(buf, "eligible") == true
  local saved = cache.unstaged._read(buf, "saved")
  if
    not saved
    or saved.revision ~= version.saved_revision
    or (saved.revision == "missing" and saved.eligible ~= eligible)
  then
    saved = read_saved(path, eligible)
    saved.eligible = eligible
    cache.unstaged._write(buf, "saved", saved)
    cache.unstaged._write(buf, "raw_index_text", nil)
  end
  local token = cache.unsaved.begin(buf, version)
  local ok, unsaved =
    pcall(require("mini.diff.hunks_loader.unsaved").compute, saved, text, opts)
  cache.unsaved.publish(
    buf,
    token,
    ok and unsaved
      or { status = "failed", reason = tostring(unsaved), hunks = {} }
  )
  local reference = cache.unstaged._read(buf, "ref_text")
  if
    saved.status == "ready"
    and reference ~= cache.unstaged._read(buf, "raw_index_text")
  then
    local raw_ok, raw = pcall(
      require("mini.diff.hunks_loader.unstaged").compute,
      reference,
      saved.text,
      opts
    )
    cache.unstaged._write(buf, "saved_hunks", raw_ok and raw.hunks or {})
    cache.unstaged._write(buf, "saved_status", raw_ok and "ready" or "failed")
    cache.unstaged._write(buf, "raw_index_text", reference)
  elseif saved.status ~= "ready" then
    cache.unstaged._write(buf, "saved_hunks", {})
    cache.unstaged._write(buf, "saved_status", saved.status)
  end
  cache.unstaged._write(buf, "version", version)
  cache.untracked._write(
    buf,
    "hunks",
    eligible and cache.unstaged._read(buf, "hunks") or {}
  )
  cache.untracked._write(buf, "version", version)
  cache.untracked._write(buf, "status", eligible and "ready" or "unavailable")
end

-- Shared generation/attachment coordination for the two asynchronous Git reads.
-- No loader owns a second authoritative copy of hunk data.
function M.refresh(buf_id, H, MiniDiff)
  local attachment, git = H.cache[buf_id], H.git_cache[buf_id]
  if not attachment or not git then
    return
  end
  local name = attachment.path
  -- Capture identity before scheduling: disable/reload must invalidate even a
  -- reference read which has not started its process yet.
  vim.schedule(function()
    if H.cache[buf_id] ~= attachment or H.git_cache[buf_id] ~= git then
      return
    end
    git.request = (git.request or 0) + 1
    local request = git.request
    cache.unstaged._write(buf_id, "reference_request", request)
    cache.unstaged.begin(buf_id, { reference_request = request })
    cache.untracked.begin(buf_id, { reference_request = request })
    local function current()
      return H.cache[buf_id] == attachment
        and H.git_cache[buf_id] == git
        and git.request == request
        and vim.api.nvim_buf_get_name(buf_id) == name
    end
    attachment.ref_pending, attachment.ref_error = true, nil
    H.pending_state(buf_id)
    if git.watch_logs then
      git.watch_logs()
    end
    if git.watch_ref then
      git.watch_ref()
    end
    git.staged = {
      status = git.staged and "updating" or "loading",
      hunks = {},
      buffer_hunks = {},
    }
    git.staged_ready = nil
    cache.staged.begin(buf_id, { reference_request = request })
    local index_done, staged_done, index_missing = false, false, false
    local function publish_staged()
      if not current() or not index_done or not staged_done then
        return
      end
      local staged = git.staged
      if attachment.ref_error then
        staged.status, staged.reason = "failed", attachment.ref_error
        staged.hunks, staged.buffer_hunks = {}, {}
      elseif staged.status == "loading" or staged.status == "updating" then
        git.staged_ready = true
      end
      -- A successfully read staged deletion proves the absent index path has
      -- an empty baseline. An arbitrary failed index read does not.
      if index_missing and git.staged_ready then
        local deleted = #staged.hunks > 0
        for _, hunk in ipairs(staged.hunks) do
          deleted = deleted and hunk.type == "delete"
        end
        if deleted then
          MiniDiff.set_ref_text(buf_id, "")
        else
          staged.status, staged.reason, git.staged_ready =
            "unavailable", "No usable index reference", nil
        end
      end
      H.schedule_diff_update(buf_id, 0)
      vim.api.nvim_buf_call(buf_id, function()
        vim.api.nvim_exec_autocmds("User", { pattern = "MiniDiffStateChanged" })
      end)
    end
    local function set_index(code, text, err, untracked)
      if not current() then
        return
      end
      cache.untracked._write(buf_id, "eligible", untracked == true)
      cache.untracked._write(
        buf_id,
        "status",
        untracked and "updating" or "unavailable"
      )
      index_done, index_missing = true, code ~= 0
      attachment.ref_pending, attachment.ref_error = nil, err
      if err then
        H.set_state(buf_id, "failed", err)
        git.staged =
          { status = "failed", reason = err, hunks = {}, buffer_hunks = {} }
        H.update_buf_diff(buf_id, attachment)
        return
      end
      MiniDiff.set_ref_text(
        buf_id,
        code == 0 and text:gsub("\r\n", "\n") or nil
      )
      publish_staged()
    end
    -- Do not cache the buffer's path across refreshes: it may have been renamed.
    local path = H.get_buf_realpath(buf_id)
    if path == "" then
      path = name
    end
    if path == "" then
      staged_done = true
      git.staged = {
        status = "unavailable",
        reason = "No file path",
        hunks = {},
        buffer_hunks = {},
      }
      return set_index(1, "")
    end
    local cwd, basename =
      vim.fn.fnamemodify(path, ":h"), vim.fn.fnamemodify(path, ":t")
    require("mini.diff.hunks_loader.unstaged").load(
      H.git_read_reference,
      cwd,
      basename,
      current,
      set_index
    )
    require("mini.diff.hunks_loader.staged").load(
      H.git_read_reference,
      cwd,
      basename,
      function(code, patch, err)
        if not current() then
          return
        end
        staged_done = true
        local hunks, reason
        if code == 0 and not err then
          hunks, reason = require("mini.diff.hunks_loader.staged").parse(patch)
        end
        git.staged = {
          status = hunks
              and (attachment.has_result and "updating" or "loading")
            or "failed",
          reason = err
            or reason
            or (not hunks and "Could not read staged diff" or nil),
          hunks = hunks or {},
          buffer_hunks = {},
        }
        publish_staged()
      end
    )
  end)
end

return M
