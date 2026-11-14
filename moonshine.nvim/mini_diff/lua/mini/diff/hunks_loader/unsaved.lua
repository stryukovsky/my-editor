local M = {}

function M.compute(saved, text, opts)
  if saved.status ~= "ready" then
    return { status = saved.status, reason = saved.reason, hunks = {} }
  end
  local result =
    require("mini.diff.hunks_loader.unstaged").compute(saved.text, text, opts)
  return {
    status = "ready",
    hunks = result.hunks,
    saved_revision = saved.revision,
  }
end

return M
