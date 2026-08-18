--- Close zen-mode if a session is open. Safe to call when it is not.
--- @return boolean `true` if a zen window was closed
return function()
  local ok, view = pcall(require, "zen-mode.view")
  if not ok or not view.is_open() then
    return false
  end
  require("zen-mode").close()
  return true
end
