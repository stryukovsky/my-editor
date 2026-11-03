local M = {}

M.config = {
  modes = {
    minidiff_review = {
      desc = "MiniDiff review files",
      source = "minidiff_review",
    },
  },
}

function M.get(cb)
  cb(require("moonshine.diff.review").trouble_items())
end

return M
