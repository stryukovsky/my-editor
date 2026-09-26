local navigation_repeat = require "utils.navigation_repeat"

local M = {}

---@param key string
---@return boolean
function M.jump(key)
  local ok = pcall(vim.cmd, "normal! " .. vim.v.count1 .. key)
  if ok then
    require("hlslens").start()
  end
  return ok
end

--- Make `/` matches the current repeat target for n/N and ; / <A-;>.
function M.activate()
  require("hlslens").start()
  navigation_repeat.set(function()
    M.jump "n"
  end, function()
    M.jump "N"
  end, "search match")
end

--- Drop slash highlight, the last pattern, and search as the repeat target.
function M.forget()
  vim.cmd "nohlsearch"
  pcall(function()
    require("hlslens").stop()
  end)
  vim.fn.setreg("/", "")
  if navigation_repeat.name() == "search match" then
    navigation_repeat.clear()
  end
end

return M
