local commit_picker = require "telescope_pretty_git.commit_picker"
local branch_picker = require "telescope_pretty_git.branch_picker"

local M = {
  preview = require "telescope_pretty_git.preview",
}

function M.setup() end

---@param opts? table
function M.show_commits(opts)
  return commit_picker(opts)
end

---@param opts? table
function M.show_branches(opts)
  return branch_picker(opts)
end

return M
