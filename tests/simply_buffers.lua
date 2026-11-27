-- nvim --headless -u NONE -i NONE -l tests/simply_buffers.lua
local root = vim.fn.getcwd()
for _, path in ipairs {
  "data/lazy/neo-tree.nvim",
  "data/lazy/nui.nvim",
  "data/lazy/plenary.nvim",
  "data/lazy/nvim-web-devicons",
  "moonshine.nvim/buffers",
} do
  vim.opt.runtimepath:append(root .. "/" .. path)
end
vim.opt.runtimepath:append(root)

local api = vim.api
local first = api.nvim_get_current_buf()
api.nvim_buf_set_name(first, "/tmp/opencode/one.py")
local second = api.nvim_create_buf(true, false)
api.nvim_buf_set_name(second, "/tmp/opencode/two.py")
local unlisted = api.nvim_create_buf(false, true)
api.nvim_buf_set_name(unlisted, "/tmp/opencode/hidden.py")
vim.b[second].buffer_pinned = true

require("neo-tree").setup {
  sources = { "simply_buffers" },
  default_source = "simply_buffers",
  enable_git_status = false,
  source_selector = { winbar = false },
}
require("neo-tree.command").execute { action = "focus", source = "simply_buffers", position = "left" }

local state = require("neo-tree.sources.manager").get_state "simply_buffers"
local nodes = state.tree:get_nodes()
assert(#nodes == 2, "source must match listed lualine buffers")
assert(nodes[1]:get_id() == tostring(second) and nodes[2]:get_id() == tostring(first), "pinned order not retained")

local renderer = require "neo-tree.ui.renderer"
renderer.focus_node(state, tostring(first))
require("neo-tree.sources.simply_buffers.commands").open(state)
assert(api.nvim_get_current_buf() == first, "opening a node must focus its existing buffer")

package.loaded.lualine = { refresh = function() end }
require("moonshine.buffers").toggle_pin(first)
require("moonshine.buffers").toggle_pin(second)
nodes = state.tree:get_nodes()
assert(nodes[1]:get_id() == tostring(first), "pin changes must refresh the open source")

local modified = api.nvim_create_buf(true, false)
api.nvim_buf_set_name(modified, "/tmp/opencode/modified.py")
api.nvim_buf_set_lines(modified, 0, -1, false, { "unsaved" })
local terminal = api.nvim_create_buf(true, false)
api.nvim_open_term(terminal, {})
vim.bo[terminal].buflisted = true
require("neo-tree.sources.simply_buffers").navigate(state)

local commands = require "neo-tree.sources.simply_buffers.commands"
local pinned_node = state.tree:get_node(tostring(first))
local terminal_node = state.tree:get_node(tostring(terminal))
commands.yank_names_visual(state, { pinned_node, terminal_node })
local copied = vim.fn.getreg "+"
assert(copied == pinned_node.extra.plain_name .. "\n" .. terminal_node.extra.plain_name, "visual yank must use plain names")
assert(not copied:find("", 1, true), "visual yank included pin icon")

renderer.focus_node(state, tostring(modified))
commands.close_buffer(state)
assert(not api.nvim_buf_is_valid(modified), "x must close the selected buffer even when modified")

local unsaved = api.nvim_create_buf(true, false)
api.nvim_buf_set_name(unsaved, "/tmp/opencode/unsaved.py")
api.nvim_buf_set_lines(unsaved, 0, -1, false, { "unsaved" })
package.loaded["integrations.notify"] = { send = function() end }
api.nvim_set_current_win(state.winid)
commands.close_unprotected()
assert(not api.nvim_buf_is_valid(second), "X must close unprotected buffers")
assert(
  api.nvim_buf_is_valid(first) and api.nvim_buf_is_valid(terminal) and api.nvim_buf_is_valid(unsaved),
  "X must preserve pinned, terminal, and unsaved buffers"
)
print "simply_buffers: list, open, visual yank, x, and X passed"
