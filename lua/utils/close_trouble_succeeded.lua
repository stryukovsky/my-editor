local trouble_main = require "trouble"

local M = {}

---@param mode string
function M.close_mode(mode)
  if trouble_main.is_open(mode) then
    pcall(function()
      trouble_main.close(mode)
    end)
  end
  if mode ~= "minidiff_review" then
    return
  end
  local ok, View = pcall(require, "trouble.view")
  if not ok then
    return
  end
  local session = require("configs.minidiff_review").session()
  for _, entry in ipairs(View.get { mode = mode } or {}) do
    local view = entry.view
    if view and view.close then
      pcall(function()
        view:close()
      end)
      local fu = view.first_update
      if not session and fu and fu.is_pending and fu:is_pending() then
        fu:next(function()
          if not require("configs.minidiff_review").session() then
            pcall(function()
              view:close()
            end)
          end
        end)
      end
    end
  end
end

--- Close every Trouble view this config uses as a bottom/list UI.
--- @return boolean `true` if those views were closed. `false` if a mini.diff
--- review is still active — that list must be quit with `q` first, so other
--- Trouble modes are left alone.
function M.close_all()
  local review = require "configs.minidiff_review"
  if review.session() then
    if not review.finish_review() then
      return false
    end
  else
    M.close_mode "minidiff_review"
  end
  for _, mode in ipairs {
    "lsp",
    "diagnostics",
    "telescope",
    "telescope_files",
    "global_results",
    "file_results",
    "qflist",
    "quickfix",
    "dap_breakpoints",
  } do
    M.close_mode(mode)
  end
  return true
end

return setmetatable(M, {
  __call = function(_, ...)
    return M.close_all(...)
  end,
})
