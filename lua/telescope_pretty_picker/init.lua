local commit_picker = require "telescope_pretty_picker.commit_picker"
local branch_picker = require "telescope_pretty_picker.branch_picker"
local visible_picker = require "telescope_pretty_picker.visible_picker"

local M = {
  preview = require "telescope_pretty_picker.preview",
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

---@param opts? { state?: table }
function M.show_visible(opts)
  return visible_picker(opts)
end

---@param opts? table
function M.show_search(opts)
  return require("telescope_pretty_picker.search_picker").open(opts)
end

function M.show_visual_search()
  return require("telescope_pretty_picker.search_picker").visual()
end

return M
